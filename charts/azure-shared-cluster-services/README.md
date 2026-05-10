# Azure Shared Cluster Services

A Helm chart for deploying shared Azure Service Bus and PostgreSQL Flexible Server for multi-tenant Kubernetes clusters. This chart uses Azure Service Operator (ASO) to provision and manage Azure resources declaratively.

## Overview

This chart deploys:
- **Azure Service Bus Namespace** - Shared messaging infrastructure for all tenants
- **Azure PostgreSQL Flexible Server** - Shared database server for tenant applications

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- [Azure Service Operator v2](https://azure.github.io/azure-service-operator/) installed in your cluster
- Azure subscription with appropriate permissions

## Installation

### Quick Start

```bash
helm install shared-services ./azure-shared-cluster-services \
  --set global.subscriptionId="your-sub-id" \
  --set global.resourceGroup="shared-rg" \
  --set sharedServiceBus.enabled=true \
  --set sharedServiceBus.name="shared-servicebus" \
  --set postgresqlFlexibleServer.enabled=true \
  --set postgresqlFlexibleServer.name="shared-postgres"
```

### Production Installation

Create a `values.yaml` file:

```yaml
global:
  subscriptionId: "your-subscription-id"
  resourceGroup: "shared-services-rg"
  location: "northeurope"
  tags:
    environment: "production"
    cost-center: "shared-infrastructure"

sharedServiceBus:
  enabled: true
  name: "prod-shared-servicebus"
  sku: "Premium"
  capacity: 2
  zoneRedundant: true
  disableLocalAuth: true
  tags:
    purpose: "multi-tenant-messaging"

postgresqlFlexibleServer:
  enabled: true
  name: "prod-shared-postgres"
  version: "16"
  sku:
    name: "Standard_D4s_v3"
    tier: "GeneralPurpose"
  storage:
    sizeGB: 256
    autoGrow: "Enabled"
  backup:
    retentionDays: 30
    geoRedundantBackup: "Enabled"
  highAvailability:
    mode: "ZoneRedundant"
  administrator:
    username: "psqladmin"
    passwordSecretName: "postgres-admin-secret"
  firewallRules:
    - name: "AllowAzureServices"
      startIpAddress: "0.0.0.0"
      endIpAddress: "0.0.0.0"
  databases:
    - name: "tenant1_db"
      charset: "UTF8"
      collation: "en_US.utf8"
    - name: "tenant2_db"
      charset: "UTF8"
      collation: "en_US.utf8"
  configurations:
    - name: "max_connections"
      value: "500"
  tags:
    purpose: "multi-tenant-database"
```

Install:

```bash
helm install shared-services ./azure-shared-cluster-services -f values.yaml
```

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.subscriptionId` | Azure subscription ID | `""` |
| `global.resourceGroup` | Azure resource group name | `""` |
| `global.location` | Azure region | `"northeurope"` |
| `global.tags` | Common tags for all resources | `{}` |

### Service Bus Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sharedServiceBus.enabled` | Enable Service Bus | `false` |
| `sharedServiceBus.name` | Namespace name | `""` |
| `sharedServiceBus.sku` | SKU (Basic, Standard, Premium) | `"Standard"` |
| `sharedServiceBus.capacity` | Capacity for Premium (1-16) | `1` |
| `sharedServiceBus.zoneRedundant` | Zone redundancy (Premium only) | `false` |
| `sharedServiceBus.disableLocalAuth` | Disable local authentication | `true` |
| `sharedServiceBus.minimumTlsVersion` | Minimum TLS version | `"1.2"` |
| `sharedServiceBus.publicNetworkAccess` | Public network access | `"Enabled"` |

### PostgreSQL Flexible Server Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresqlFlexibleServer.enabled` | Enable PostgreSQL | `false` |
| `postgresqlFlexibleServer.name` | Server name (globally unique) | `""` |
| `postgresqlFlexibleServer.version` | PostgreSQL version (11-16) | `"16"` |
| `postgresqlFlexibleServer.sku.name` | SKU name | `"Standard_D2s_v3"` |
| `postgresqlFlexibleServer.sku.tier` | SKU tier | `"GeneralPurpose"` |
| `postgresqlFlexibleServer.storage.sizeGB` | Storage size in GB (32-16384) | `128` |
| `postgresqlFlexibleServer.storage.autoGrow` | Auto grow storage | `"Enabled"` |
| `postgresqlFlexibleServer.backup.retentionDays` | Backup retention (7-35) | `7` |
| `postgresqlFlexibleServer.backup.geoRedundantBackup` | Geo-redundant backup | `"Disabled"` |
| `postgresqlFlexibleServer.highAvailability.mode` | HA mode (Disabled, ZoneRedundant, SameZone) | `"Disabled"` |
| `postgresqlFlexibleServer.administrator.username` | Admin username | `"psqladmin"` |
| `postgresqlFlexibleServer.administrator.passwordSecretName` | Secret name for password | `""` |
| `postgresqlFlexibleServer.network.publicNetworkAccess` | Public network access | `"Enabled"` |
| `postgresqlFlexibleServer.firewallRules` | Firewall rules | `[]` |
| `postgresqlFlexibleServer.databases` | Databases to create | `[]` |
| `postgresqlFlexibleServer.configurations` | Server configurations | `[]` |

## Accessing Resources

### Service Bus Endpoint

The Service Bus fully qualified namespace is exported to a ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: <servicebus-name>-config
data:
  SERVICEBUS_ENDPOINT: <servicebus-name>.servicebus.windows.net
```

### PostgreSQL Connection

The PostgreSQL host is exported to a ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: <postgres-name>-config
data:
  POSTGRES_HOST: <postgres-name>.postgres.database.azure.com
```

## Multi-Tenant Usage

### Tenant Applications Using Service Bus

```yaml
env:
  - name: SERVICEBUS_ENDPOINT
    valueFrom:
      configMapKeyRef:
        name: shared-servicebus-config
        key: SERVICEBUS_ENDPOINT
  - name: SERVICEBUS_QUEUE_NAME
    value: "tenant-queue"
```

### Tenant Applications Using PostgreSQL

```yaml
env:
  - name: POSTGRES_HOST
    valueFrom:
      configMapKeyRef:
        name: shared-postgres-config
        key: POSTGRES_HOST
  - name: POSTGRES_DATABASE
    value: "tenant1_db"
  - name: POSTGRES_USER
    valueFrom:
      secretKeyRef:
        name: tenant1-db-credentials
        key: username
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: tenant1-db-credentials
        key: password
```

## Creating Tenant Databases

Add databases in your values:

```yaml
postgresqlFlexibleServer:
  databases:
    - name: "tenant1_db"
      charset: "UTF8"
      collation: "en_US.utf8"
    - name: "tenant2_db"
      charset: "UTF8"
      collation: "en_US.utf8"
```

## High Availability

For production workloads, enable zone redundancy:

```yaml
sharedServiceBus:
  sku: "Premium"
  zoneRedundant: true

postgresqlFlexibleServer:
  highAvailability:
    mode: "ZoneRedundant"
  backup:
    geoRedundantBackup: "Enabled"
```

## Monitoring

Check resource status:

```bash
# Service Bus
kubectl get namespace.servicebus.azure.com -n shared-services

# PostgreSQL
kubectl get flexibleserver.dbforpostgresql.azure.com -n shared-services

# ConfigMaps
kubectl get configmaps -n shared-services
```

## Troubleshooting

### Resources not provisioning

Check ASO status:
```bash
kubectl describe <resource-type> <resource-name> -n shared-services
kubectl logs -n azureserviceoperator-system -l app.kubernetes.io/name=azure-service-operator
```

### Connection issues

Verify ConfigMaps are populated:
```bash
kubectl get configmap shared-servicebus-config -o yaml
kubectl get configmap shared-postgres-config -o yaml
```

## Uninstallation

```bash
helm uninstall shared-services -n shared-services
```

**Note**: Azure resources will be deleted. Ensure you have backups before uninstalling.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

MIT
