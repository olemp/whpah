module "five31-frontend" {
  source     = "./modules/frontend"
  depends_on = [module.kube-hetzner]

  name              = "five31"
  github_repository = "bakseter/five31"
  root_directory    = "frontend"

  environment = [
    {
      key   = "NEXT_PUBLIC_BACKEND_URL"
      value = module.five31-backend.fqdn
    },
    {
      key   = "NEXT_PUBLIC_BACKEND_API_VERSION"
      value = "v2"
    },
    {
      key    = "NEXT_PUBLIC_ENVIRONMENT"
      value  = "production"
      target = ["production"]
    },
    {
      key    = "NEXT_PUBLIC_ENVIRONMENT"
      value  = "preview"
      target = ["preview"]
    },
    {
      key    = "NEXT_PUBLIC_ENVIRONMENT"
      value  = "development"
      target = ["development"]
    },
    {
      key   = "AUTH_SECRET"
      value = random_password.five31-frontend-auth-secret.result
    },
    {
      key   = "AUTH_GOOGLE_ID"
      value = var.auth_google_id
    }
  ]

  secret_environment = [
    {
      key   = "AUTH_GOOGLE_SECRET"
      value = var.auth_google_secret
    }
  ]
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
