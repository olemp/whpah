provider "helm" {
  kubernetes {
    config_path = module.kube-hetzner.kubeconfig
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo"

  atomic           = true
  create_namespace = true
  namespace        = "argocd"
}
