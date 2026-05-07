# Azure Microservice Helm Chart

A comprehensive Helm chart for deploying microservices on Azure Kubernetes Service (AKS) with integrated Azure services.

## Features

- ✅ Kubernetes Deployment with configurable replicas
- ✅ Service (ClusterIP/LoadBalancer)
- ✅ Ingress support (NGINX/Application Gateway)
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Pod Disruption Budget (PDB)
- ✅ Azure Key Vault integration via CSI driver
- ✅ Azure Application Insights monitoring
- ✅ Azure Workload Identity support
- ✅ ConfigMap for application configuration
- ✅ Health probes (liveness, readiness, startup)
- ✅ Resource limits and requests
- ✅ Security contexts
- ✅ Network policies
- ✅ ServiceMonitor for Prometheus metrics

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Azure Kubernetes Service (AKS)
- Azure Service Operator (optional, for Azure resource management)
- Secrets Store CSI Driver (for Key Vault integration)
- Azure Workload Identity (recommended for secure authentication)

## Installation

### Basic Installation

```bash
helm install myapp ./charts/azure-microservice \
  --set image.repository=myacr.azurecr.io/myapp \
  --set image.tag=v1.0.0 \
  --namespace myapp --create-namespace
```

### With Azure Key Vault

```bash
helm install myapp ./charts/azure-microservice \
  --set image.repository=myacr.azurecr.io/myapp \
  --set azureKeyVault.enabled=true \
  --set azureKeyVault.keyVaultName=my-keyvault \
  --set azureKeyVault.tenantId=00000000-0000-0000-0000-000000000000 \
  --namespace myapp --create-namespace
```

### With Ingress

```bash
helm install myapp ./charts/azure-microservice \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --namespace myapp --create-namespace
```

### Full Configuration Example

```bash
helm install myapp ./charts/azure-microservice \
  --set image.repository=myacr.azurecr.io/myapp \
  --set image.tag=v1.0.0 \
  --set replicaCount=3 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.example.com \
  --set azureKeyVault.enabled=true \
  --set azureKeyVault.keyVaultName=my-keyvault \
  --set azureApplicationInsights.enabled=true \
  --set azureApplicationInsights.connectionString="InstrumentationKey=..." \
  --namespace myapp --create-namespace
```

## Configuration

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `myacr.azurecr.io/myapp` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Deployment Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `8080` |

### Azure Workload Identity

| Parameter | Description | Default |
|-----------|-------------|---------|
| `workloadIdentity.enabled` | Enable automatic workload identity setup | `false` |
| `workloadIdentity.resourceGroup` | Resource group for managed identity | `""` |
| `workloadIdentity.location` | Azure location | `northeurope` |
| `workloadIdentity.identityName` | Managed identity name | Release name |
| `workloadIdentity.oidcIssuerUrl` | AKS OIDC issuer URL | `""` (required) |
| `workloadIdentity.serviceAccountNamespace` | Service account namespace | Release namespace |
| `workloadIdentity.serviceAccountName` | Service account name | Auto-generated |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `70` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory % | `80` |

### Azure Key Vault

| Parameter | Description | Default |
|-----------|-------------|---------|
| `azureKeyVault.enabled` | Enable Key Vault integration | `false` |
| `azureKeyVault.keyVaultName` | Key Vault name | `""` |
| `azureKeyVault.tenantId` | Azure tenant ID | `""` |
| `azureKeyVault.secrets` | Secrets to mount | `[]` |

Example secrets configuration:

```yaml
azureKeyVault:
  enabled: true
  keyVaultName: my-keyvault
  tenantId: 00000000-0000-0000-0000-000000000000
  secrets:
    - secretName: database-password
      objectName: db-password
      objectType: secret
    - secretName: api-key
      objectName: external-api-key
      objectType: secret
```

### Azure Application Insights

| Parameter | Description | Default |
|-----------|-------------|---------|
| `azureApplicationInsights.enabled` | Enable App Insights | `false` |
| `azureApplicationInsights.instrumentationKey` | Instrumentation key | `""` |
| `azureApplicationInsights.connectionString` | Connection string | `""` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.hosts` | Ingress hosts | `[]` |
| `ingress.tls` | TLS configuration | `[]` |

### Health Probes

The chart includes default health probes that you can customize:

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: http
  initialDelaySeconds: 10
  periodSeconds: 5

startupProbe:
  httpGet:
    path: /health/startup
    port: http
  initialDelaySeconds: 0
  periodSeconds: 5
  failureThreshold: 30
```

## Azure Workload Identity Setup

The chart can automatically create and configure Azure Workload Identity resources.

### Prerequisites

1. **Enable OIDC Issuer on AKS cluster:**
```bash
az aks update -g myResourceGroup -n myAKSCluster --enable-oidc-issuer
```

2. **Get the OIDC Issuer URL:**
```bash
OIDC_ISSUER=$(az aks show -n myAKSCluster -g myResourceGroup --query "oidcIssuerProfile.issuerUrl" -o tsv)
echo $OIDC_ISSUER
```

3. **Install Azure Service Operator** (if not already installed):
```bash
helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
helm upgrade --install aso2 aso2/azure-service-operator \
  --create-namespace \
  --namespace azureserviceoperator-system \
  --set azureSubscriptionID=$SUBSCRIPTION_ID \
  --set azureTenantID=$TENANT_ID \
  --set azureClientID=$CLIENT_ID \
  --set azureClientSecret=$CLIENT_SECRET
```

### Installation with Workload Identity

```bash
# Get OIDC Issuer URL
OIDC_ISSUER=$(az aks show -n myAKSCluster -g myResourceGroup --query "oidcIssuerProfile.issuerUrl" -o tsv)

# Install the chart with workload identity enabled
helm install myapp ./charts/azure-microservice \
  --set image.repository=myacr.azurecr.io/myapp \
  --set image.tag=v1.0.0 \
  --set workloadIdentity.enabled=true \
  --set workloadIdentity.resourceGroup=myapp-rg \
  --set workloadIdentity.location=northeurope \
  --set workloadIdentity.identityName=myapp-identity \
  --set workloadIdentity.oidcIssuerUrl=$OIDC_ISSUER \
  --namespace myapp --create-namespace
```

This will automatically create:
- Azure Resource Group
- Azure User-Assigned Managed Identity
- Federated Identity Credential (linking K8s ServiceAccount to Azure Identity)
- Kubernetes ServiceAccount with proper annotations
- Pod labels and annotations for workload identity

### Grant Permissions to Managed Identity

After installation, grant necessary permissions to the managed identity:

```bash
# Get the managed identity client ID
IDENTITY_CLIENT_ID=$(az identity show -g myapp-rg -n myapp-identity --query clientId -o tsv)

# Grant Key Vault access
az keyvault set-policy \
  --name mykeyvault \
  --object-id $(az identity show -g myapp-rg -n myapp-identity --query principalId -o tsv) \
  --secret-permissions get list

# Grant Azure Storage access
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/myapp-rg
```

## Azure Workload Identity Setup

1. Create a managed identity:
```bash
# This is now automatic when workloadIdentity.enabled=true
# But you can also create manually:
az identity create --name myapp-identity --resource-group myapp-rg
```

2. Get the client ID:
```bash
CLIENT_ID=$(az identity show --name myapp-identity --resource-group myapp-rg --query clientId -o tsv)
```

3. Install with workload identity:
```bash
# Using the automated setup (recommended)
helm install myapp ./charts/azure-microservice \
  --set workloadIdentity.enabled=true \
  --set workloadIdentity.oidcIssuerUrl=$OIDC_ISSUER \
  --set workloadIdentity.resourceGroup=myapp-rg

# Or using manual setup
helm install myapp ./charts/azure-microservice \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=$CLIENT_ID \
  --set podAnnotations."azure\.workload\.identity/use"="true"
```

## Examples

See the `examples/` directory for complete configuration examples:
- Basic deployment
- With Azure Key Vault
- With Application Insights
- Full production setup

## Uninstallation

```bash
helm uninstall myapp -n myapp
```

## Support

For issues or questions, please refer to the project repository.

## License

This chart is provided as-is for use with Azure Kubernetes Service.
