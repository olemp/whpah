variable "name" {
  type = string
}

variable "image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "environment" {
  type = map(string)
}

variable "secret_environment" {
  type      = map(string)
  sensitive = true
}
