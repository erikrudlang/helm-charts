# GitHub Actions Workflows

## Publish Helm Charts to ACR

This workflow automatically builds and publishes Helm charts to Azure Container Registry.

### Prerequisites

Before the workflow can run successfully, you need to configure the following secrets in your GitHub repository:

#### Required Secrets

1. **AZURE_CLIENT_ID** - The Client ID of your Azure Service Principal or Managed Identity
2. **AZURE_TENANT_ID** - Your Azure Active Directory Tenant ID
3. **AZURE_SUBSCRIPTION_ID** - Your Azure Subscription ID
4. **ACR_NAME** - The name of your Azure Container Registry (without .azurecr.io)

### Setting up Azure Authentication

#### Option 1: Using Workload Identity Federation (Recommended)

1. Create an Azure AD App Registration
2. Configure federated credentials for GitHub Actions
3. Grant the service principal `AcrPush` role on your ACR

```bash
# Create service principal
az ad sp create-for-rbac --name "github-actions-helm-publisher" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.ContainerRegistry/registries/{acr-name}

# Configure federated credential
az ad app federated-credential create \
  --id <APPLICATION_OBJECT_ID> \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:{org}/{repo}:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### Option 2: Using Service Principal with Secret

If you prefer to use client secret authentication, modify the Azure Login step to use:

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

And create the `AZURE_CREDENTIALS` secret with:

```bash
az ad sp create-for-rbac --name "github-actions-helm" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.ContainerRegistry/registries/{acr-name} \
  --sdk-auth
```

### Granting ACR Push Permissions

```bash
# Get the service principal object ID
SP_OBJECT_ID=$(az ad sp show --id <CLIENT_ID> --query id -o tsv)

# Grant AcrPush role
az role assignment create \
  --assignee-object-id $SP_OBJECT_ID \
  --role AcrPush \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

### Workflow Triggers

The workflow runs on:
- **Push to main branch** - Automatically publishes charts when code is merged
- **Version tags** - Publishes when you create version tags (e.g., v1.0.0)
- **Pull requests** - Validates charts can be packaged (doesn't publish)
- **Manual trigger** - Can be triggered manually from GitHub Actions UI

### Using Published Charts

After the workflow runs successfully, you can use the charts with:

```bash
# Login to ACR
az acr login --name {acr-name}

# Pull a chart
helm pull oci://{acr-name}.azurecr.io/helm/{chart-name} --version {version}

# Install a chart
helm install my-release oci://{acr-name}.azurecr.io/helm/{chart-name} --version {version}
```

### Chart Versioning

The workflow uses the version specified in each chart's `Chart.yaml` file. To publish a new version:

1. Update the `version` field in `charts/{chart-name}/Chart.yaml`
2. Commit and push your changes
3. The workflow will automatically publish the new version

### Troubleshooting

**Chart already exists error:**
- Each chart version can only be published once
- Increment the version in Chart.yaml before pushing

**Authentication failed:**
- Verify all required secrets are set correctly
- Check that the service principal has `AcrPush` role on the ACR
- Ensure the federated credential subject matches your repository

**Helm push fails:**
- Verify your ACR name is correct (without .azurecr.io suffix)
- Check that OCI support is enabled in your ACR (it's enabled by default in newer ACRs)
