variable "name" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "root_directory" {
  type = string
}

variable "environment" {
  type = map(object({
    value   = string
    targets = optional(set(string), ["production", "preview", "development"])
  }))
}

variable "secret_environment" {
  type = map(object({
    value   = string
    targets = optional(set(string), ["production", "preview", "development"])
  }))
  sensitive = true
}
