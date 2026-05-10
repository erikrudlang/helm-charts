{{/*
Expand the name of the chart.
*/}}
{{- define "azure-shared-cluster-services.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "azure-shared-cluster-services.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "azure-shared-cluster-services.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "azure-shared-cluster-services.labels" -}}
helm.sh/chart: {{ include "azure-shared-cluster-services.chart" . }}
{{ include "azure-shared-cluster-services.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "azure-shared-cluster-services.selectorLabels" -}}
app.kubernetes.io/name: {{ include "azure-shared-cluster-services.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Merge global and resource-specific tags
*/}}
{{- define "azure-shared-cluster-services.tags" -}}
{{- $globalTags := .Values.global.tags | default dict }}
{{- $resourceTags := .resourceTags | default dict }}
{{- merge $resourceTags $globalTags | toYaml }}
{{- end }}
