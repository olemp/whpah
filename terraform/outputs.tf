output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}

output "cert_manager_values" {
  value = module.kube-hetzner.cert_manager_values
}

output "traefik_values" {
  value = module.kube-hetzner.traefik_values
}

output "cilium_values" {
  value = module.kube-hetzner.cilium_values
}
