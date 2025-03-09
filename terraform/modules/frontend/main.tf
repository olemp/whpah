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
  domain     = "${var.name}-bakseter-net.vercel.app"
}

resource "vercel_project_environment_variables" "environment" {
  project_id = vercel_project.next_project.id
  variables = [
    for env in var.environment
    : {
      key    = env.key
      value  = env.value
      target = env.target
    }
  ]
}

resource "vercel_project_environment_variables" "secret_environment" {
  project_id = vercel_project.next_project.id
  variables = [
    for env in var.secret_environment
    : {
      key       = env.key
      value     = env.value
      target    = env.target
      sensitive = true
    }
  ]
}
