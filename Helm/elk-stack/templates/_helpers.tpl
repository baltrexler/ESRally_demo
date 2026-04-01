{{/*
Expand the name of the chart.
*/}}
{{- define "elk-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "elk-stack.fullname" -}}
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
Chart label
*/}}
{{- define "elk-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elk-stack.labels" -}}
helm.sh/chart: {{ include "elk-stack.chart" . }}
{{ include "elk-stack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elk-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "elk-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "elk-stack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "elk-stack.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Elasticsearch fully-qualified service name
*/}}
{{- define "elk-stack.elasticsearch.fullname" -}}
{{- printf "%s-elasticsearch" (include "elk-stack.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Logstash fully-qualified service name
*/}}
{{- define "elk-stack.logstash.fullname" -}}
{{- printf "%s-logstash" (include "elk-stack.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Kibana fully-qualified service name
*/}}
{{- define "elk-stack.kibana.fullname" -}}
{{- printf "%s-kibana" (include "elk-stack.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
