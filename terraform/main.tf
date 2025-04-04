provider "hcloud" {
  token = var.hcloud_token
}

module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }

  source  = "kube-hetzner/kube-hetzner/hcloud"
  version = "2.16.1"

  hcloud_token    = var.hcloud_token
  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  control_plane_nodepools = [
    {
      name        = "control-plane",
      server_type = "cx22",
      location    = var.location
      labels      = [],
      taints      = [],
      count       = 1
    }
  ]

  agent_nodepools = [
    {
      name        = "agent",
      server_type = "cx22",
      location    = var.location
      labels      = [],
      taints      = [],
      count       = 1
    }
  ]

  network_region = "eu-central" # locations 'fns1', 'nbg1' and 'hel1'

  enable_klipper_metal_lb = "true"

  automatically_upgrade_k3s = false
  system_upgrade_use_drain  = true
  automatically_upgrade_os  = false

  disable_network_policy = true

  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  create_kubeconfig    = false
  create_kustomization = false
}

// Uncomment this block after cluster has been created.
provider "kubernetes" {
  host = module.kube-hetzner.kubeconfig_data.host

  client_certificate     = module.kube-hetzner.kubeconfig_data.client_certificate
  client_key             = module.kube-hetzner.kubeconfig_data.client_key
  cluster_ca_certificate = module.kube-hetzner.kubeconfig_data.cluster_ca_certificate
}

// Uncomment this block after cluster has been created.
provider "helm" {
  kubernetes = {
    host = module.kube-hetzner.kubeconfig_data.host

    client_certificate     = module.kube-hetzner.kubeconfig_data.client_certificate
    client_key             = module.kube-hetzner.kubeconfig_data.client_key
    cluster_ca_certificate = module.kube-hetzner.kubeconfig_data.cluster_ca_certificate
  }
}

// Uncomment this block after cluster has been created.
resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "7.8.23"

  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait_for_jobs    = true

  values = [<<EOT
global:
  networkPolicy:
    create: true

configs:
  repositories:
    argocd:
      url: https://github.com/bakseter/platform
EOT
  ]
}

locals {
  argocd_root_application = file("${path.module}/manifests/argocd-root-application.yml")
}

resource "null_resource" "kubectl-apply-manifest" {
  triggers = {
    manifest = local.argocd_root_application
  }

  provisioner "local-exec" {
    command = "curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubectl && chmod +x kubectl"
  }

  provisioner "local-exec" {
    command     = "./kubectl apply --force --kubeconfig <(echo \"$KUBECONFIG\" | base64 -d) -f <(echo \"$MANIFEST\" | base64 -d)"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = base64encode(module.kube-hetzner.kubeconfig)
      MANIFEST   = base64encode(local.argocd_root_application)
    }
  }
}
