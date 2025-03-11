provider "hcloud" {
  token = var.hcloud_token
}

module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }

  source = "kube-hetzner/kube-hetzner/hcloud"

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

  network_region         = "eu-central" # locations 'fns1', 'nbg1' and 'hel1'
  load_balancer_type     = var.load_balancer_sku
  load_balancer_location = var.location

  automatically_upgrade_k3s = false
  system_upgrade_use_drain  = true
  automatically_upgrade_os  = false

  extra_firewall_rules = [
    {
      description = "For NodePort"
      direction   = "in"
      protocol    = "tcp"
      port        = "30000-32767"
      source_ips = [
        "0.0.0.0/0",
        "::/0"
      ]
      destination_ips = [] # Won't be used for this rule
    },
  ]

  disable_network_policy = true

  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  create_kubeconfig    = false
  create_kustomization = false

  traefik_values = <<EOT
additionalArguments:
- --providers.kubernetesingress.ingressendpoint.publishedservice=traefik/traefik
autoscaling:
  enabled: true
  maxReplicas: 10
  minReplicas: 1
api: {}
deployment:
  replicas: 1
globalArguments: []
image:
  tag: null
podDisruptionBudget:
  enabled: true
  maxUnavailable: 33%
ports:
  web:
    redirectTo:
      port: websecure
    forwardedHeaders:
      trustedIPs:
      - 127.0.0.1/32
      - 10.0.0.0/8
    proxyProtocol:
      trustedIPs:
      - 127.0.0.1/32
      - 10.0.0.0/8
  websecure:
    forwardedHeaders:
      trustedIPs:
      - 127.0.0.1/32
      - 10.0.0.0/8
    proxyProtocol:
      trustedIPs:
      - 127.0.0.1/32
      - 10.0.0.0/8
resources:
  limits:
    cpu: 300m
    memory: 150Mi
  requests:
    cpu: 100m
    memory: 50Mi
service:
  annotations:
    load-balancer.hetzner.cloud/algorithm-type: round_robin
    load-balancer.hetzner.cloud/disable-private-ingress: "true"
    load-balancer.hetzner.cloud/disable-public-network: "false"
    load-balancer.hetzner.cloud/health-check-interval: 15s
    load-balancer.hetzner.cloud/health-check-retries: "3"
    load-balancer.hetzner.cloud/health-check-timeout: 10s
    load-balancer.hetzner.cloud/ipv6-disabled: "false"
    load-balancer.hetzner.cloud/location: ${var.location}
    load-balancer.hetzner.cloud/name: k3s
    load-balancer.hetzner.cloud/type: ${var.load_balancer_sku}
    load-balancer.hetzner.cloud/use-private-ip: "true"
    load-balancer.hetzner.cloud/uses-proxyprotocol: "true"
  enabled: true
  type: LoadBalancer
EOT
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

// Uncomment this block if you want to use Vercel for frontend deployment.
provider "vercel" {
  api_token = var.vercel_token
}

// Uncomment this block after cluster has been created.
resource "helm_release" "keel" {
  name       = "keel"
  chart      = "keel"
  repository = "https://charts.keel.sh"
  version    = "1.0.5"

  namespace        = "keel"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait_for_jobs    = true

  values = [<<EOT
helmProvider:
  enabled: false
rbac:
  enabled: false
secret:
  enabled: false
EOT
  ]
}
