variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "vercel_token" {
  type      = string
  sensitive = true
}

variable "auth_google_id" {
  type = string
}

variable "auth_google_secret" {
  type      = string
  sensitive = true
}

variable "location" {
  type    = string
  default = "hel1"
}

variable "load_balancer_sku" {
  type    = string
  default = "lb11"
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_private_key" {
  type      = string
  sensitive = true
}
