terraform {
  cloud {
    organization = "bakseter"

    workspaces {
      name = "platform"
    }
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.43.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.5.0"
}
