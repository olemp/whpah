variable "app_name" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "image" {
  type = string
}

variable "port" {
  type = number
}

variable "environment" {
  type = map(string)
}

variable "secret_environment" {
  type      = map(string)
  sensitive = true
}
