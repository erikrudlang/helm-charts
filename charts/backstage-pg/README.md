# Backstage with CloudNativePG

A Helm chart for deploying [Backstage](https://backstage.io/) developer portal with a PostgreSQL database managed by [CloudNativePG](https://cloudnative-pg.io/).

## Overview

This chart deploys:
- **Backstage** - An open platform for building developer portals
- **CloudNativePG Cluster** - A PostgreSQL database managed by the CloudNativePG operator

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- [CloudNativePG Operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) installed in your cluster

### Installing CloudNativePG Operator

```bash
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.22/releases/cnpg-1.22.0.yaml
```

Or with Helm:

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg \
  --namespace cnpg-system \
  --create-namespace \
  cnpg/cloudnative-pg
```

## Installation

### Quick Start

```bash
helm install backstage ./backstage-pg \
  --set backstage.baseUrl="http://localhost:7007" \
  --set backstage.backendUrl="http://localhost:7007"
```

### Production Installation

Create a `values.yaml` file:

```yaml
image:
  repository: my-registry/backstage
  tag: "1.0.0"
  
replicaCount: 2

backstage:
  baseUrl: "https://backstage.example.com"
  backendUrl: "https://backstage.example.com"
  
  app:
    title: "My Company Developer Portal"
  
  organization:
    name: "My Company"
  
  catalog:
    locations:
      - type: url
        target: https://github.com/my-org/software-catalog/blob/main/catalog-info.yaml

postgresql:
  enabled: true
  cluster:
    name: "backstage-pg"
    instances: 3
    storage:
      size: "20Gi"
      storageClass: "fast-ssd"
  auth:
    username: "backstage"
    database: "backstage"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: backstage.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: backstage-tls
      hosts:
        - backstage.example.com

resources:
  requests:
    memory: "1Gi"
    cpu: "1000m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

Install:

```bash
helm install backstage ./backstage-pg -f values.yaml
```

## Configuration

### Backstage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.registry` | Image registry | `ghcr.io` |
| `image.repository` | Image repository | `backstage/backstage` |
| `image.tag` | Image tag | `latest` |
| `replicaCount` | Number of replicas | `1` |
| `backstage.baseUrl` | Base URL for Backstage | `http://localhost:7007` |
| `backstage.backendUrl` | Backend URL | `http://localhost:7007` |
| `backstage.app.title` | Application title | `Backstage` |
| `backstage.organization.name` | Organization name | `My Company` |

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.cluster.name` | Cluster name | `backstage-pg` |
| `postgresql.cluster.instances` | Number of instances | `1` |
| `postgresql.cluster.storage.size` | Storage size | `10Gi` |
| `postgresql.cluster.storage.storageClass` | Storage class | `""` |
| `postgresql.auth.username` | Database username | `backstage` |
| `postgresql.auth.database` | Database name | `backstage` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Target port | `7007` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts[0].host` | Hostname | `backstage.example.com` |
| `ingress.tls` | TLS configuration | `[]` |

## Custom Backstage Image

This chart uses the official Backstage image by default. For production use, you should build your own Backstage image with your plugins and configuration.

### Building a Custom Image

1. Create a Backstage app:
```bash
npx @backstage/create-app@latest
```

2. Add your plugins and customize `app-config.yaml`

3. Build and push the image:
```bash
yarn build:backend
docker build . -f packages/backend/Dockerfile --tag my-registry/backstage:1.0.0
docker push my-registry/backstage:1.0.0
```

4. Update your values:
```yaml
image:
  repository: my-registry/backstage
  tag: "1.0.0"
```

## Accessing Backstage

### Port Forward

```bash
kubectl port-forward svc/backstage 7007:80
```

Then open http://localhost:7007 in your browser.

### Via Ingress

If ingress is enabled, access Backstage at the configured hostname.

## Database Management

The PostgreSQL database is managed by CloudNativePG. Common operations:

### Check cluster status

```bash
kubectl get cluster backstage-pg
```

### View pods

```bash
kubectl get pods -l cnpg.io/cluster=backstage-pg
```

### Connect to database

```bash
kubectl exec -it backstage-pg-1 -- psql -U backstage -d backstage
```

### Backup

CloudNativePG supports automated backups. Configure in values:

```yaml
postgresql:
  cluster:
    backup:
      enabled: true
      schedule: "0 0 * * *"
      retentionPolicy: "30d"
```

## Catalog Configuration

Add catalog locations in your values:

```yaml
backstage:
  catalog:
    locations:
      - type: url
        target: https://github.com/my-org/backstage-catalog/blob/main/catalog.yaml
      - type: url
        target: https://github.com/my-org/another-repo/blob/main/catalog-info.yaml
```

## Troubleshooting

### Backstage won't start

Check logs:
```bash
kubectl logs -l app.kubernetes.io/name=backstage-pg
```

Common issues:
- Database not ready: Wait for PostgreSQL cluster to be healthy
- Configuration errors: Check ConfigMap and environment variables

### Database connection issues

Check PostgreSQL cluster status:
```bash
kubectl get cluster backstage-pg -o yaml
```

Verify secrets:
```bash
kubectl get secret backstage-pg-app -o yaml
```

### Cannot access via ingress

Check ingress status:
```bash
kubectl get ingress
kubectl describe ingress backstage-pg
```

## Upgrading

```bash
helm upgrade backstage ./backstage-pg -f values.yaml
```

## Uninstalling

```bash
helm uninstall backstage
```

**Note**: This will also delete the PostgreSQL cluster and data. Ensure you have backups before uninstalling.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

MIT
