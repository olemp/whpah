output "database_password" {
  value = random_password.postgres.result
}

output "database_url" {
  value = "${kubernetes_service_v1.postgres.metadata.0.name}.${kubernetes_namespace_v1.postgres.metadata.0.name}.svc.cluster.local:${kubernetes_service_v1.postgres.spec.0.port.0.port}/${var.database_name}"
}
