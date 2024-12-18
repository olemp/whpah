locals {
  repositories = [
    "531"
  ]
}

resource "helm_release" "argocd" {
  count = 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  atomic           = true
  create_namespace = true
  force_update     = true
  namespace        = "argocd"
  recreate_pods    = true

  dynamic "set" {
    for_each = local.repositories

    content {
      name  = "repositories.${set.value}.name"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = local.repositories

    content {
      name  = "repositories.${set.value}.url"
      value = "https://github.com/bakseter/${set.value}"
    }
  }

  dynamic "set" {
    for_each = local.repositories

    content {
      name  = "repositories.${set.value}.type"
      value = "git"
    }
  }
}
