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
  type = list(object({
    key    = string
    value  = string
    target = optional(set(string), ["production", "preview", "development"])
  }))
}

variable "secret_environment" {
  type = list(object({
    key    = string
    value  = string
    target = optional(set(string), ["production", "preview"])
  }))
  sensitive = true
}
