## How it works

Azure deployments are asynchronous.

This tool:

1. Starts deployment with --no-wait
2. Polls deployment operations
3. Parses operation states
4. Displays:
   - Progress bar
   - Resource states
   - Deployment status

## Flow details

1. Deployment starts asynchronously:
   - `az deployment sub create ... --no-wait`
   - or `az deployment group create ... --no-wait`
2. `monitor-bicep-deployment.sh` polls ARM operations.
3. The script computes:
   - total operation count
   - succeeded count
   - failed count
   - progress percentage (`succeeded / total`)
4. Current resources are grouped by provisioning state:
   - Running
   - Completed
   - Failed
5. Monitoring stops on:
   - Succeeded (exit 0)
   - Failed (exit 1 + failed operation details)
   - Timeout (exit 1)

## Azure DevOps template vs local CLI

The templates in `templates/` and local CLI usage are functionally the same:

- Start deployment with `az deployment ... create`
- Optionally pass `--no-wait`
- Run `scripts/monitor-bicep-deployment.sh` with scope + deployment name

This makes local dry-runs and documentation consistent with pipeline behavior.
