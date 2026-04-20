![GitHub stars](https://img.shields.io/github/stars/ArtMeij/bicep-deployment-progress)
![GitHub license](https://img.shields.io/github/license/ArtMeij/bicep-deployment-progress)
![GitHub issues](https://img.shields.io/github/issues/ArtMeij/bicep-deployment-progress)

# 🚀 Bicep Deployment Progress

Terraform-like deployment experience for Bicep in your Azure DevOps pipeline.

Adds:

* 📊 Progress bar
* 🎨 Colored output
* 🔄 Live deployment tracking
* 📦 Resource-level visibility

---

## ✨ Features

* Works with:

  * `az deployment sub create`
  * `az deployment group create`
* Real-time polling of ARM operations
* Progress based on deployment operations
* Shows:

  * Running resources
  * Completed resources
  * Failed resources
* Timeout protection

---

## 🔧 Why?

Bicep deployments:

* Are asynchronous
* Provide limited feedback
* Feel like a "black box"

This project adds visibility and control.

---

## 🚀 Quick Start

### Before you start

```bash
az login
az account set --subscription "<subscription-id-or-name>"
```

Make sure `jq` is installed and available in your shell.

### Subscription deployment

```yaml
- template: templates/deploy-bicep-sub.yml
  parameters:
    azureServiceConnection: my-connection
    deploymentName: my-deployment
    location: northeurope
    templateFile: main.bicep
    parameterFile: main.bicepparam
```

Equivalent local CLI flow:

```bash
DEPLOYMENT="my-deployment-$(date +%s)"
LOCATION="northeurope"

az deployment sub create \
  --name "$DEPLOYMENT" \
  --location "$LOCATION" \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --no-wait

bash ./scripts/monitor-bicep-deployment.sh sub "" "$DEPLOYMENT"
```

---

### Resource group deployment

```yaml
- template: templates/deploy-bicep-rg.yml
  parameters:
    azureServiceConnection: my-connection
    resourceGroupName: my-rg
    deploymentName: my-deployment
    templateFile: main.bicep
    parameterFile: main.bicepparam
```

Equivalent local CLI flow:

```bash
DEPLOYMENT="my-deployment-$(date +%s)"
RG="my-rg"

az deployment group create \
  --name "$DEPLOYMENT" \
  --resource-group "$RG" \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --no-wait

bash ./scripts/monitor-bicep-deployment.sh group "$RG" "$DEPLOYMENT"
```

---

## 📊 Example Output

```
===== 12:01 | Elapsed: 2 min =====
==== Overall status: Running ====
[████████████--------] 60% (6/10)

Running:
acr
keyvault

Completed:
vnet
subnet


```

---

## ⚠️ Limitations

* Progress % is based on ARM operations (not exact)
* Total number of operations may change during deployment
* Uses polling (no native streaming from Azure)

---

## 🧠 How it works

Short version:

1. Start deployment with `--no-wait`
2. Poll deployment operations
3. Calculate progress from operation states
4. Render progress bar + resource states

Detailed flow and behavior: see [`docs/how-it-works.md`](docs/how-it-works.md).

---

## 🛠️ Requirements

* Azure CLI
* jq
* Bash

---

## 🤝 Contributing

PRs welcome!

---

## 🆘 Troubleshooting

Common issues:

* **AuthorizationFailed / Forbidden**
  * Check role assignments for the service principal or logged-in user.
* **Resource group not found**
  * Verify `resourceGroupName` and selected subscription.
* **Template or parameter errors**
  * Validate paths to `.bicep` / `.bicepparam` files.
* **Long-running or throttled deployments**
  * Increase timeout: `MAX_MINUTES=120`.
  * Reduce poll pressure: `INTERVAL=20`.

For known behavior limitations, also see [`docs/limitations.md`](docs/limitations.md).

---

## 📄 License

MIT
