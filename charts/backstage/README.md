# Backstage Helm Chart

A Helm chart for deploying Backstage on Kubernetes with Azure PostgreSQL integration.

## Prerequisites

- Kubernetes cluster with Azure Service Operator installed
- Helm 3.x
- Azure subscription with necessary permissions

## Installation

### Install from local chart

```bash
helm install backstage ./charts/backstage -n backstage --create-namespace
```

### Install with custom values

```bash
helm install backstage ./charts/backstage -n backstage --create-namespace \
  --set image.tag=v1.0.0 \
  --set postgresql.administratorPassword=YourSecurePassword
```

### Upgrade

```bash
helm upgrade backstage ./charts/backstage -n backstage
```

### Uninstall

```bash
helm uninstall backstage -n backstage
```

## Configuration

The following table lists the configurable parameters and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of Backstage replicas | `1` |
| `image.repository` | Backstage image repository | `acraksdemo.azurecr.io/backstage` |
| `image.tag` | Backstage image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `namespace.create` | Create namespace | `true` |
| `namespace.name` | Namespace name | `backstage` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.serverName` | PostgreSQL server name | `erudlang-backstage-postgres` |
| `postgresql.administratorPassword` | PostgreSQL admin password | `ChangeMe123!@#` |

## PostgreSQL Configuration

This chart deploys an Azure PostgreSQL Flexible Server using Azure Service Operator. Make sure to:

1. Change the default administrator password in `values.yaml`
2. Configure firewall rules if needed
3. Ensure Azure Service Operator is properly configured in your cluster

## GitHub App Configuration

Update the GitHub App credentials in `values.yaml` with your base64-encoded values:

```yaml
github:
  appId: "<base64-encoded-app-id>"
  clientId: "<base64-encoded-client-id>"
  clientSecret: "<base64-encoded-client-secret>"
  privateKey: "<base64-encoded-private-key>"
  webhookSecret: "<base64-encoded-webhook-secret>"
```

## ArgoCD Integration

This chart includes ArgoCD-compatible labels for GitOps workflows. The common labels are applied to all resources:

```yaml
commonLabels:
  app.kubernetes.io/name: backstage
  app.kubernetes.io/managed-by: argocd
```

## Values File Structure

See `values.yaml` for the complete configuration options.

## Testing

Test the chart rendering:

```bash
helm template backstage ./charts/backstage -n backstage
```

Validate the chart:

```bash
helm lint ./charts/backstage
```

## Support

For issues or questions, please refer to the Backstage documentation or open an issue in the repository.
