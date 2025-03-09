output "namespace" {
  value = kubernetes_namespace_v1.namespace.metadata[0].name
}

output "fqdn" {
  value = "https://${local.host}"
}
