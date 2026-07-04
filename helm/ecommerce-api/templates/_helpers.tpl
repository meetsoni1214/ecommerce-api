{{- define "ecommerce-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ecommerce-api.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "ecommerce-api.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "ecommerce-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "ecommerce-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ecommerce-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "ecommerce-api.secretName" -}}
{{- if .Values.secrets.existingSecret -}}
{{- .Values.secrets.existingSecret -}}
{{- else -}}
{{- printf "%s-secrets" (include "ecommerce-api.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "ecommerce-api.postgresql.fullname" -}}
{{- printf "%s-postgresql" (include "ecommerce-api.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ecommerce-api.postgresql.secretName" -}}
{{- printf "%s-postgresql" (include "ecommerce-api.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ecommerce-api.azurite.fullname" -}}
{{- printf "%s-azurite" (include "ecommerce-api.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ecommerce-api.databaseUrl" -}}
{{- if .Values.postgresql.enabled -}}
postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "ecommerce-api.postgresql.fullname" . }}:{{ .Values.postgresql.service.port }}/{{ .Values.postgresql.auth.database }}?schema=public
{{- else -}}
{{- .Values.secrets.databaseUrl -}}
{{- end -}}
{{- end -}}

{{- define "ecommerce-api.azureStorageConnectionString" -}}
{{- if .Values.azurite.enabled -}}
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://{{ include "ecommerce-api.azurite.fullname" . }}:{{ .Values.azurite.service.port }}/devstoreaccount1;
{{- else -}}
{{- .Values.secrets.azureStorageConnectionString -}}
{{- end -}}
{{- end -}}
