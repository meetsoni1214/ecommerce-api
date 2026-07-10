resource "helm_release" "ecommerce_api" {
  name      = "ecommerce-api"
  chart     = "../../helm/ecommerce-api"
  namespace = "default"
  wait      = true

  values = [
    file("${path.module}/../../helm/ecommerce-api/values.aks-prod.yaml")
  ]
}