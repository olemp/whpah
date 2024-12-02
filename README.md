# platform

## Bootstrap

1. Create project `platform` in Hetzner Cloud and workspace `platform` in Terraform Cloud.
2. Get API token from Hetzner Cloud with read/write access, and save as both GitHub secret and Terraform Cloud environment variable with name `HCLOUD_TOKEN`.
3. Get API token from Terraform Cloud and save as GitHub secret with name `TF_API_TOKEN`.
4. Push to `master`, triggering GitHub Actions to build and deploy the platform using Packer and Terraform.
