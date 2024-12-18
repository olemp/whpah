provider "kubernetes" {
  host = module.kube-hetzner.kubeconfig_data.host

  client_certificate     = module.kube-hetzner.kubeconfig_data.client_certificate
  client_key             = module.kube-hetzner.kubeconfig_data.client_key
  cluster_ca_certificate = module.kube-hetzner.kubeconfig_data.cluster_ca_certificate
}

locals {
  issuer_name        = "api"
  issuer_secret_name = "${local.issuer_name}-issuer-secret"
}

resource "kubernetes_manifest" "cluster-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = local.issuer_name
    }

    spec = {
      acme = {
        email  = "andreas_tkd@hotmail.com"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = {
          name = local.issuer_secret_name
        }

        solvers = [
          {
            http01 = {
              ingress = {
                ingressClassName : "traefik"
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_ingress_v1" "api" {
  metadata {
    name      = "api"
    namespace = "traefik"

    annotations = {
      "cert-manager.io/issuer" : local.issuer_name
    }
  }

  spec {
    tls {
      hosts       = ["api.bakseter.net"]
      secret_name = local.issuer_secret_name
    }

    rule {
      host = "api.bakseter.net"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "531" # TODO: change

              port {
                name = "web"
              }
            }
          }
        }
      }
    }
  }
}
