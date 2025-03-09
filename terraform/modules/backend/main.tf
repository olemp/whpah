locals {
  host = "api.${var.name}.bakseter.net"
}

resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name = var.name
  }
}

resource "kubernetes_deployment_v1" "deployment" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.namespace.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        container {
          name  = var.name
          image = var.image

          port {
            container_port = var.container_port
          }

          dynamic "env" {
            for_each = var.environment

            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "env" {
            for_each = var.secret_environment

            content {
              name = env.key

              value_from {
                secret_key_ref {
                  name = kubernetes_secret_v1.secret-environment[0].metadata[0].name
                  key  = env.key
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_secret_v1" "secret-environment" {
  count = length(var.secret_environment) > 0 ? 1 : 0

  metadata {
    name      = "${var.name}-secret-environment"
    namespace = kubernetes_namespace_v1.namespace.metadata[0].name
  }

  data = {
    for key, value in var.secret_environment : key => value
  }
}

resource "kubernetes_service_v1" "service" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.namespace.metadata[0].name
  }

  spec {
    selector = {
      app = var.name
    }

    port {
      port        = 80
      target_port = var.container_port
    }
  }
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"

    metadata = {
      name      = var.name
      namespace = kubernetes_namespace_v1.namespace.metadata[0].name
    }

    spec = {
      acme = {
        email  = "andreas_tkd@hotmail.com"
        server = "https://acme-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = {
          name = "${var.name}-tls"
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
    name      = var.name
    namespace = kubernetes_namespace_v1.namespace.metadata[0].name

    annotations = {
      "cert-manager.io/issuer" : kubernetes_manifest.issuer.manifest.metadata.name
    }
  }

  spec {
    tls {
      hosts       = [local.host]
      secret_name = "${var.name}-tls"
    }

    rule {
      host = local.host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = var.name

              port {
                number = kubernetes_service_v1.service.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}
