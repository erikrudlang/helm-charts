# Post-Installation Steps for Azure Workload Identity

After installing the chart with `workloadIdentity.enabled=true`, you need to manually update the ServiceAccount with the managed identity client ID.

## Why?

The Azure Service Operator creates the managed identity asynchronously. The ServiceAccount needs the client ID from the created identity, but Helm templates are evaluated before Azure resources are provisioned.

## Steps

### 1. Wait for Managed Identity to be Created

```bash
# Watch the managed identity creation
kubectl get userassignedidentity -n <namespace> -w

# Wait until STATUS shows "Ready"
kubectl wait --for=condition=Ready userassignedidentity/<identity-name> -n <namespace> --timeout=300s
```

### 2. Get the Client ID

```bash
# Get the client ID from the created identity
CLIENT_ID=$(kubectl get userassignedidentity <identity-name> -n <namespace> -o jsonpath='{.status.clientId}')
echo "Client ID: $CLIENT_ID"
```

### 3. Update ServiceAccount

```bash
# Patch the service account with the client ID
kubectl annotate serviceaccount <service-account-name> \
  -n <namespace> \
  azure.workload.identity/client-id=$CLIENT_ID \
  --overwrite
```

### 4. Restart Pods

```bash
# Restart the deployment to pick up the new annotation
kubectl rollout restart deployment/<deployment-name> -n <namespace>
```

## Complete Example

```bash
# Set variables
export NAMESPACE="myapp"
export IDENTITY_NAME="myapp-identity"
export SA_NAME="myapp-azure-microservice"
export DEPLOYMENT_NAME="myapp-azure-microservice"

# Wait for identity
kubectl wait --for=condition=Ready userassignedidentity/$IDENTITY_NAME -n $NAMESPACE --timeout=300s

# Get client ID
CLIENT_ID=$(kubectl get userassignedidentity $IDENTITY_NAME -n $NAMESPACE -o jsonpath='{.status.clientId}')

# Update service account
kubectl annotate serviceaccount $SA_NAME \
  -n $NAMESPACE \
  azure.workload.identity/client-id=$CLIENT_ID \
  --overwrite

# Restart deployment
kubectl rollout restart deployment/$DEPLOYMENT_NAME -n $NAMESPACE

# Verify
kubectl describe serviceaccount $SA_NAME -n $NAMESPACE | grep azure.workload.identity/client-id
```

## Automated Script

Save this as `setup-workload-identity.sh`:

```bash
#!/bin/bash
set -e

NAMESPACE=${1:-myapp}
RELEASE_NAME=${2:-myapp}

echo "Setting up Azure Workload Identity for release: $RELEASE_NAME in namespace: $NAMESPACE"

# Derive resource names
IDENTITY_NAME="${RELEASE_NAME}-azure-microservice"
SA_NAME="${RELEASE_NAME}-azure-microservice"
DEPLOYMENT_NAME="${RELEASE_NAME}-azure-microservice"

echo "Waiting for managed identity to be ready..."
kubectl wait --for=condition=Ready userassignedidentity/$IDENTITY_NAME -n $NAMESPACE --timeout=300s

echo "Getting client ID..."
CLIENT_ID=$(kubectl get userassignedidentity $IDENTITY_NAME -n $NAMESPACE -o jsonpath='{.status.clientId}')

if [ -z "$CLIENT_ID" ]; then
  echo "Error: Failed to get client ID"
  exit 1
fi

echo "Client ID: $CLIENT_ID"

echo "Updating service account..."
kubectl annotate serviceaccount $SA_NAME \
  -n $NAMESPACE \
  azure.workload.identity/client-id=$CLIENT_ID \
  --overwrite

echo "Restarting deployment..."
kubectl rollout restart deployment/$DEPLOYMENT_NAME -n $NAMESPACE

echo "Waiting for rollout to complete..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE

echo "✅ Azure Workload Identity setup complete!"
echo ""
echo "Verify with:"
echo "kubectl describe serviceaccount $SA_NAME -n $NAMESPACE"
```

Run it:
```bash
chmod +x setup-workload-identity.sh
./setup-workload-identity.sh myapp myapp
```
