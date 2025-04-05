# WHPAT

**W**e **H**ave **P**latform **A**t **H**ome — a dirt cheap Kubernetes developer platform using Argo CD, Hetzner Cloud, and Terraform Cloud.

Based on [kube-hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner).

## Create Your Own

**1.** Create project `platform` in Hetzner Cloud and workspace `platform` in Terraform Cloud.
Terraform Cloud username/organization should be the same as your GitHub username/organization.

**2.** Run this command to create a Hetzner Cloud context for the project:

```bash
hcloud context create platform
```

**3.** Get API token from Hetzner Cloud with read/write access, and save as both GitHub secret named `HCLOUD_TOKEN` and as a Terraform Cloud variable with name `hcloud_token`.

**4.** Get API token from Terraform Cloud and save as GitHub secret with name `TF_API_TOKEN`.

**5.** Create an ED25519 SSH key pair and save them as the two Terraform Cloud variables `ssh_public_key` and `ssh_private_key`.

**6.** Push to `master`, triggering GitHub Actions to build and deploy the platform using Packer and Terraform.
