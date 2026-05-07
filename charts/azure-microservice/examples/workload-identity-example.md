# Example: Complete Azure Microservice with Workload Identity

This example demonstrates a full production-ready deployment with Azure Workload Identity.

## Prerequisites

```bash
# Set variables
export CLUSTER_NAME="myaks"
export RESOURCE_GROUP="myaks-rg"
export APP_NAME="myapp"
export APP_NAMESPACE="myapp"
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Enable OIDC Issuer on AKS
az aks update -g $RESOURCE_GROUP -n $CLUSTER_NAME --enable-oidc-issuer --enable-workload-identity

# Get OIDC Issuer URL
export OIDC_ISSUER=$(az aks show -n $CLUSTER_NAME -g $RESOURCE_GROUP --query "oidcIssuerProfile.issuerUrl" -o tsv)
```

## Installation

```bash
# Install with workload identity enabled
helm install $APP_NAME ../../azure-microservice \
  --namespace $APP_NAMESPACE \
  --create-namespace \
  --set image.repository=myacr.azurecr.io/myapp \
  --set image.tag=v1.0.0 \
  --set workloadIdentity.enabled=true \
  --set workloadIdentity.resourceGroup="${APP_NAME}-rg" \
  --set workloadIdentity.location=northeurope \
  --set workloadIdentity.identityName="${APP_NAME}-identity" \
  --set workloadIdentity.oidcIssuerUrl=$OIDC_ISSUER \
  --set azureKeyVault.enabled=true \
  --set azureKeyVault.keyVaultName=mykeyvault \
  --set azureKeyVault.tenantId=$TENANT_ID \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix
```

## Grant Permissions

After installation, grant the necessary permissions to the managed identity:

```bash
# Get the managed identity
IDENTITY_CLIENT_ID=$(kubectl get userassignedidentity ${APP_NAME}-identity -n $APP_NAMESPACE -o jsonpath='{.status.clientId}')
IDENTITY_PRINCIPAL_ID=$(kubectl get userassignedidentity ${APP_NAME}-identity -n $APP_NAMESPACE -o jsonpath='{.status.principalId}')

# Grant Key Vault access
az keyvault set-policy \
  --name mykeyvault \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --secret-permissions get list \
  --key-permissions get list \
  --certificate-permissions get list

# Grant Azure Storage access
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/${APP_NAME}-rg

# Grant Azure Service Bus access
az role assignment create \
  --role "Azure Service Bus Data Sender" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/${APP_NAME}-rg

az role assignment create \
  --role "Azure Service Bus Data Receiver" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/${APP_NAME}-rg
```

## Verify Installation

```bash
# Check all resources
kubectl get all -n $APP_NAMESPACE

# Check managed identity
kubectl get userassignedidentity -n $APP_NAMESPACE

# Check federated credential
kubectl get federatedidentitycredential -n $APP_NAMESPACE

# Check pod has workload identity labels
kubectl get pods -n $APP_NAMESPACE -l azure.workload.identity/use=true

# Check service account annotations
kubectl describe sa ${APP_NAME}-azure-microservice -n $APP_NAMESPACE

# Test the application
curl http://myapp.example.com/health
```

## Troubleshooting

### Check managed identity status
```bash
kubectl describe userassignedidentity ${APP_NAME}-identity -n $APP_NAMESPACE
```

### Check federated credential status
```bash
kubectl describe federatedidentitycredential ${APP_NAME}-federated-credential -n $APP_NAMESPACE
```

### View pod logs
```bash
kubectl logs -l app.kubernetes.io/name=azure-microservice -n $APP_NAMESPACE --tail=100
```

### Verify workload identity token
```bash
# Exec into pod
kubectl exec -it deployment/${APP_NAME}-azure-microservice -n $APP_NAMESPACE -- sh

# Inside pod, check for token
cat /var/run/secrets/azure/tokens/azure-identity-token

# Test Azure authentication
curl -H "Authorization: Bearer $(cat /var/run/secrets/azure/tokens/azure-identity-token)" \
  "https://management.azure.com/subscriptions?api-version=2020-01-01"
```

## Cleanup

```bash
helm uninstall $APP_NAME -n $APP_NAMESPACE
kubectl delete namespace $APP_NAMESPACE
```
