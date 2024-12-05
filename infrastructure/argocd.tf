provider "helm" {
  kubernetes {
    host     = module.kube-hetzner.kubeconfig_data.host

    client_certificate     = module.kube-hetzner.kubeconfig_data.client_certificate
    client_key             = module.kube-hetzner.kubeconfig_data.client_key
    cluster_ca_certificate = module.kube-hetzner.kubeconfig_data.cluster_ca_certificate
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  atomic           = true
  create_namespace = true
  namespace        = "argocd"
}
