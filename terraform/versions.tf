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
      version = "3.0.0-pre2"
    }

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.43"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    vercel = {
      source  = "vercel/vercel"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.5.0"
}
