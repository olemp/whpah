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
    load-balancer.hetzner.cloud/name: k3s-traefik
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

// Uncomment this block if you want to use Vercel for frontend deployment.
provider "vercel" {
  api_token = var.vercel_token
}

module "five31-frontend" {
  source     = "./modules/frontend"
  depends_on = [module.kube-hetzner]

  name              = "five31"
  github_repository = "bakseter/five31"
  root_directory    = "frontend"

  environment = {
    "NEXT_PUBLIC_BACKEND_URL" = {
      value = module.five31-backend.fqdn
    },
    "NEXT_PUBLIC_BACKEND_API_VERSION" = {
      value = "v2"
    },
    "NEXT_PUBLIC_ENVIRONMENT" = {
      value   = "production"
      targets = ["production"]
    },
    "NEXT_PUBLIC_ENVIRONMENT" = {
      value   = "preview"
      targets = ["preview"]
    },
    "NEXT_PUBLIC_ENVIRONMENT" = {
      value   = "development"
      targets = ["development"]
    },
    "AUTH_SECRET" = {
      value = random_password.five31-frontend-auth-secret.result
    },
    "AUTH_GOOGLE_ID" = {
      value = var.auth_google_id
    }
  }

  secret_environment = {
    "AUTH_GOOGLE_SECRET" = {
      value = var.auth_google_secret
    }
  }
}

resource "random_password" "five31-frontend-auth-secret" {
  length           = 64
  special          = true
  override_special = "_%@"
}

module "five31-backend" {
  source     = "./modules/backend"
  depends_on = [module.kube-hetzner]

  name           = "five31"
  image          = "ghcr.io/bakseter/531/backend:latest"
  container_port = 8080

  environment = {
    "DATABASE_USERNAME" : "postgres",
    "DATABASE_URL" : "jdbc:postgresql://${module.postgres.database_url}",
  }

  secret_environment = {
    "DATABASE_PASSWORD" : module.postgres.database_password
  }
}

module "postgres" {
  source     = "./modules/postgres"
  depends_on = [module.kube-hetzner]
}
