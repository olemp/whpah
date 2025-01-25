provider "hcloud" {
  token = var.hcloud_token
}

module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }

  source = "kube-hetzner/kube-hetzner/hcloud"

  hcloud_token = var.hcloud_token

  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  network_region = "eu-central" # change to `us-east` if location is ash
  control_plane_nodepools = [
    {
      name        = "control-plane",
      server_type = "cx22",
      location    = "hel1",
      labels      = [],
      taints      = [],
      count       = 1
    }
  ]

  agent_nodepools = [
    {
      name        = "agent-small",
      server_type = "cx22",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 1
    }
  ]

  load_balancer_type     = "lb11"
  load_balancer_location = "hel1"

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
    load-balancer.hetzner.cloud/location: fsn1
    load-balancer.hetzner.cloud/name: k3s-traefik
    load-balancer.hetzner.cloud/type: lb11
    load-balancer.hetzner.cloud/use-private-ip: "true"
    load-balancer.hetzner.cloud/uses-proxyprotocol: "true"
  enabled: true
  type: LoadBalancer
EOT
}

// Uncomment the rest of this file after Kubernetes cluster has been created:

/*
provider "kubernetes" {
  host = module.kube-hetzner.kubeconfig_data.host

  client_certificate     = module.kube-hetzner.kubeconfig_data.client_certificate
  client_key             = module.kube-hetzner.kubeconfig_data.client_key
  cluster_ca_certificate = module.kube-hetzner.kubeconfig_data.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host = module.kube-hetzner.kubeconfig_data.host

    client_certificate     = module.kube-hetzner.kubeconfig_data.client_certificate
    client_key             = module.kube-hetzner.kubeconfig_data.client_key
    cluster_ca_certificate = module.kube-hetzner.kubeconfig_data.cluster_ca_certificate
  }
}
*/


module "five31" {
  depends_on = [module.kube-hetzner]
  source     = "./modules/app"
  for_each   = tomap({})

  app_name  = each.key
  subdomain = each.value["subdomain"]
}
