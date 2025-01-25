resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name = var.app_name
  }
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"

    metadata = {
      name      = "${var.app_name}-issuer"
      namespace = kubernetes_namespace_v1.namespace.metadata[0].name
    }

    spec = {
      acme = {
        email  = "andreas_tkd@hotmail.com"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = {
          name = "${var.app_name}-tls"
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

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace_v1.namespace.metadata[0].name

    annotations = {
      "cert-manager.io/issuer" : "${var.app_name}-issuer"
    }
  }

  spec {
    tls {
      hosts       = ["${var.subdomain}.bakseter.net"]
      secret_name = "${var.app_name}-tls"
    }

    rule {
      host = "${var.subdomain}.bakseter.net"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "${var.app_name}-service"

              port {
                number = 8000
              }
            }
          }
        }
      }
    }
  }
}
