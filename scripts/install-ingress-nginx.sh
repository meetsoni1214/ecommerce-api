#!/usr/bin/env sh
set -eu

NAMESPACE="${NAMESPACE:-ingress-nginx}"
RELEASE="${RELEASE:-ingress-nginx}"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install "$RELEASE" ingress-nginx/ingress-nginx \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set 'controller.service.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path=/healthz'
