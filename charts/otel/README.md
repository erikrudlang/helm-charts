# OpenTelemetry Instrumentation and Collector CRDs for .NET Applications

This Helm chart creates OpenTelemetry Operator custom resources (`Instrumentation` and `OpenTelemetryCollector`) that enable automatic .NET instrumentation and sidecar collector injection for your applications.

## Features

- **CRD-Based Configuration**: Creates `Instrumentation` and `OpenTelemetryCollector` custom resources
- **Annotation-Driven Injection**: Automatically inject instrumentation and sidecar via pod annotations
- **.NET Auto-Instrumentation**: Zero-code instrumentation for .NET applications
- **Sidecar Pattern**: OTel Collector runs alongside your application container
- **Flexible Exporters**: Configure exporters to send telemetry to any backend
- **Operator Managed**: OpenTelemetry Operator handles all injection and lifecycle management

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- **OpenTelemetry Operator installed** (see installation instructions below)
- A .NET application container image

## Installing the OpenTelemetry Operator

Before installing this chart, you must install the OpenTelemetry Operator:

```bash
# Install cert-manager (required by the operator)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# Install OpenTelemetry Operator
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
```

Or using Helm:

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --set "manager.collectorImage.repository=otel/opentelemetry-collector-contrib" \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.autoGenerateCert.enabled=true
```

## Installing the Chart

This chart only creates the CRD resources. You still need to create your own application deployment.

```bash
# Install the OpenTelemetry CRD resources
helm install otel-config ./charts/otel

# Then create your application deployment with the required annotations
kubectl apply -f your-app-deployment.yaml
```

## Configuration

### OpenTelemetry Collector Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `otelCollector.mode` | Collector deployment mode | `sidecar` |
| `otelCollector.image` | OTel Collector image | `otel/opentelemetry-collector-contrib:0.98.0` |
| `otelCollector.config` | Collector configuration (YAML string) | See values.yaml |

### .NET Instrumentation Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `instrumentation.enabled` | Enable .NET auto-instrumentation | `true` |
| `instrumentation.dotnet.image` | .NET auto-instrumentation image | `ghcr.io/.../autoinstrumentation-dotnet:1.3.0` |
| `instrumentation.exporter.endpoint` | OTLP endpoint | `http://localhost:4318` |
| `instrumentation.sampler.type` | Trace sampler type | `parentbased_traceidratio` |

## Configuring Exporters

### Azure Monitor Example

```yaml
otelCollector:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    
    processors:
      batch:
      memory_limiter:
        check_interval: 1s
        limit_mib: 200
    
    exporters:
      azuremonitor:
        connection_string: "${APPLICATIONINSIGHTS_CONNECTION_STRING}"
    
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [azuremonitor]
        metrics:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [azuremonitor]
        logs:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [azuremonitor]
```

### OTLP Backend Example

```yaml
otelCollector:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    
    processors:
      batch:
    
    exporters:
      otlp:
        endpoint: "your-backend:4317"
        tls:
          insecure: false
          cert_file: /path/to/cert.pem
    
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [otlp]
```

### Prometheus Example

```yaml
otelCollector:
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    
    exporters:
      prometheus:
        endpoint: "0.0.0.0:8889"
    
    service:
      pipelines:
        metrics:
          receivers: [otlp]
          exporters: [prometheus]
```

## Using with Your Application

After installing this chart, annotate your application deployment to enable instrumentation and collector injection:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-dotnet-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-dotnet-app
  template:
    metadata:
      labels:
        app: my-dotnet-app
      annotations:
        # Enable .NET auto-instrumentation
        instrumentation.opentelemetry.io/inject-dotnet: "otel-config-dotnet-instrumentation"
        # Enable OTel Collector sidecar
        sidecar.opentelemetry.io/inject: "otel-config-sidecar"
    spec:
      containers:
      - name: my-app
        image: my-dotnet-app:latest
        ports:
        - containerPort: 8080
```

**Note**: Your .NET application doesn't need any OpenTelemetry packages installed. The auto-instrumentation handles everything at runtime.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  This Helm Chart                                         │
│  ├── Instrumentation CRD                                 │
│  └── OpenTelemetryCollector CRD                         │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────┐
│    OpenTelemetry Operator                      │
│    - Watches for Instrumentation CRD           │
│    - Watches for OpenTelemetryCollector CRD    │
│    - Injects sidecars and init containers      │
└────────────────────────────────────────────────┘
                    │
                    ▼ (injects based on annotations)
┌─────────────────────────────────────┐
│     Your Application Pod            │
│  ┌──────────────────────────────┐  │
│  │  Init Container              │  │← Injected by Operator
│  │  (OTel .NET Auto-Instr)      │  │
│  └──────────────────────────────┘  │
│  ┌──────────────┐  ┌──────────────┐│
│  │              │  │              ││
│  │  .NET App    │──│  OTel        ││← Injected by Operator
│  │  Container   │  │  Collector   ││
│  │              │  │  Sidecar     ││
│  └──────────────┘  └──────────────┘│
│         │                 │         │
└─────────┼─────────────────┼─────────┘
          │                 │
          └─────OTLP────────┘
                 │
                 ▼
          Observability Backend
```

## Instrumented Libraries

The following .NET libraries are automatically instrumented:

- ASP.NET Core
- HttpClient
- SqlClient
- Entity Framework Core
- And many more...

## Troubleshooting

### Check if instrumentation is loaded:

```bash
kubectl logs <pod-name> -c <app-container> | grep OpenTelemetry
```

### View OTel Collector logs:

```bash
kubectl logs <pod-name> -c otel-collector
```

### Verify telemetry is being sent:

Check the collector logs for successful exports or use the logging exporter temporarily to see the data.

## Advanced Configuration

### Custom Instrumentation Settings

You can override any .NET auto-instrumentation environment variable:

```yaml
instrumentation:
  dotnet:
    env:
      OTEL_RESOURCE_ATTRIBUTES: "deployment.environment=production,service.version=1.0.0"
  sampler:
    type: parentbased_traceidratio
    argument: "0.5"
```

### Disable Specific Instrumentations

```yaml
instrumentation:
  dotnet:
    env:
      OTEL_DOTNET_AUTO_TRACES_ENTITYFRAMEWORKCORE_INSTRUMENTATION_ENABLED: "false"
```

## How It Works

1. **Install Operator**: The OpenTelemetry Operator is installed in your cluster
2. **Install This Chart**: Creates `Instrumentation` and `OpenTelemetryCollector` custom resources
3. **Deploy Your App**: Create your application deployment with the required annotations
4. **Automatic Injection**: The operator's mutating webhook intercepts pod creation and automatically injects:
   - Init container with .NET auto-instrumentation libraries
   - OTel Collector sidecar container
   - Required environment variables for auto-instrumentation
   - Volume mounts for instrumentation files

The annotation values must match the names of the created CRD resources (default: `<release-name>-dotnet-instrumentation` and `<release-name>-sidecar`).

## License

Apache 2.0

## Maintainer

Erik Rudlang
