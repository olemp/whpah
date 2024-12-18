locals {
  issuer_name        = "api"
  issuer_secret_name = "${local.issuer_name}-issuer-secret"
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"

    metadata = {
      name = local.issuer_name
      namespace = "531"
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
    namespace = "531"

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
              name = "svc-531" # TODO: change

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
