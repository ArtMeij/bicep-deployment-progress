#!/usr/bin/env bash
set -euo pipefail

SCOPE=$1          # sub | group
RG=$2             # empty if sub
DEPLOYMENT=$3

INTERVAL=10
MAX_MINUTES=60
START_TIME=$(date +%s)

# 🎨 Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Monitoring deployment: $DEPLOYMENT${NC}"

while true; do
  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))
  ELAPSED_MIN=$((ELAPSED / 60))

  echo ""
  echo -e "${BLUE}===== $(date) | Elapsed: ${ELAPSED_MIN} min =====${NC}"
    echo -e "${BLUE}==== Overall status: $STATUS ===={NC}"

  # Fetch operations
  if [[ "$SCOPE" == "sub" ]]; then
    OPS_JSON=$(az deployment operation sub list --name "$DEPLOYMENT" -o json 2>/dev/null || echo "[]")
    STATUS=$(az deployment sub show --name "$DEPLOYMENT" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "Running")
  else
    OPS_JSON=$(az deployment operation group list --resource-group "$RG" --name "$DEPLOYMENT" -o json 2>/dev/null || echo "[]")
    STATUS=$(az deployment group show --resource-group "$RG" --name "$DEPLOYMENT" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "Running")
  fi

  TOTAL=$(echo "$OPS_JSON" | jq length)
  SUCCEEDED=$(echo "$OPS_JSON" | jq '[.[] | select(.properties.provisioningState=="Succeeded")] | length')
  FAILED=$(echo "$OPS_JSON" | jq '[.[] | select(.properties.provisioningState=="Failed")] | length')

  # Progress %
  if [[ "$TOTAL" -gt 0 ]]; then
    PERCENT=$((SUCCEEDED * 100 / TOTAL))
  else
    PERCENT=0
  fi

  # Progress bar
  BAR_LENGTH=20
  FILLED=$((PERCENT * BAR_LENGTH / 100))
  EMPTY=$((BAR_LENGTH - FILLED))

  FILLED_BAR=$(printf "%0.s█" $(seq 1 $FILLED))
  EMPTY_BAR=$(printf "%0.s-" $(seq 1 $EMPTY))

  if [[ "$PERCENT" -eq 100 ]]; then
    COLOR=$GREEN
  else
    COLOR=$YELLOW
  fi

  echo -e "${YELLOW} [${FILLED_BAR}${EMPTY_BAR}] ${PERCENT}% (${SUCCEEDED}/${TOTAL})${NC}"
  
  # Resource states
  RUNNING=$(echo "$OPS_JSON" | jq -r '
    .[] | select(.properties.provisioningState=="Running") |
    "\(.properties.targetResource.resourceName)"
  ' | sort -u)

  SUCCEEDED=$(echo "$OPS_JSON" | jq -r '
    .[] | select(.properties.provisioningState=="Succeeded") |
    "\(.properties.targetResource.resourceName)"
  ' | sort -u)

  FAILED=$(echo "$OPS_JSON" | jq -r '
    .[] | select(.properties.provisioningState=="Failed") |
    "\(.properties.targetResource.resourceName)"
  ' | sort -u)

  if [[ -n "$RUNNING" ]]; then
    echo ""
    echo -e "${YELLOW}Running:${NC}"
    echo "$RUNNING" | while read -r r; do
      echo -e "${YELLOW}$r${NC}"
    done
  fi

  if [[ -n "$SUCCEEDED" ]]; then
    echo ""
    echo -e "${GREEN}Completed:${NC}"
    echo "$SUCCEEDED" | while read -r r; do
      echo -e "${GREEN}$r${NC}"
    done
  fi

  if [[ -n "$FAILED" ]]; then
    echo ""
    echo -e "${RED}Failed:${NC}"
    echo "$FAILED" | while read -r r; do
      echo -e "${RED}$r${NC}"
    done
  fi

  # Success
  if [[ "$STATUS" == "Succeeded" ]]; then
    echo ""
    echo -e "${BLUE}===== Deployment completed in ${ELAPSED_MIN} min =====${NC}"
    exit 0
  fi

  # Failure
  if [[ "$STATUS" == "Failed" ]]; then
    echo ""
    echo -e "${RED}===== Deployment failed after ${ELAPSED_MIN} min =====${NC}"
    echo "$OPS_JSON" | jq '[.[] | select(.properties.provisioningState=="Failed")]'
    exit 1
  fi

  # Timeout
  if [[ $ELAPSED -ge $((MAX_MINUTES * 60)) ]]; then
    echo ""
    echo -e "${RED}===== Timeout reached after ${ELAPSED_MIN} min =====${NC}"
    exit 1
  fi

  sleep $INTERVAL
done
