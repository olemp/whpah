resource "vercel_project" "next_project" {
  name                       = "${var.name}-frontend"
  framework                  = "nextjs"
  root_directory             = var.root_directory
  serverless_function_region = "arn1"
  install_command            = "pnpm i"

  git_repository = {
    type = "github"
    repo = var.github_repository
  }
}

resource "vercel_project_domain" "domain" {
  project_id = vercel_project.next_project.id
  domain     = "${var.name}.bakseter.net"
}

resource "vercel_project_environment_variables" "environment" {
  project_id = vercel_project.next_project.id
  variables = [
    for key, value in var.environment
    : {
      key    = key
      value  = value.value
      target = value.targets
    }
  ]
}

resource "vercel_project_environment_variables" "secret_environment" {
  project_id = vercel_project.next_project.id
  variables = [
    for key, value in var.secret_environment
    : {
      key       = key
      value     = value.value
      target    = value.targets
      sensitive = true
    }
  ]
}
