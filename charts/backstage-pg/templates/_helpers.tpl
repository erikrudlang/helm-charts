{{/*
Expand the name of the chart.
*/}}
{{- define "backstage-pg.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "backstage-pg.fullname" -}}
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
{{- define "backstage-pg.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "backstage-pg.labels" -}}
helm.sh/chart: {{ include "backstage-pg.chart" . }}
{{ include "backstage-pg.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "backstage-pg.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backstage-pg.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "backstage-pg.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "backstage-pg.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL host
*/}}
{{- define "backstage-pg.postgresql.host" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-rw" .Values.postgresql.cluster.name }}
{{- else }}
{{- .Values.backstage.backend.database.connection.host }}
{{- end }}
{{- end }}

{{/*
PostgreSQL secret name
*/}}
{{- define "backstage-pg.postgresql.secretName" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-app" .Values.postgresql.cluster.name }}
{{- else }}
{{- .Values.backstage.backend.database.connection.passwordSecret }}
{{- end }}
{{- end }}
