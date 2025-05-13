# WHPAH

**W**e **H**ave **P**latform **A**t **H**ome — a dirt cheap Kubernetes developer platform using Argo CD, Hetzner Cloud, and Terraform Cloud.

## What is this?

After discovering [kube-hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner) and falling in love with Argo CD,
I was amazed at how easily you can deploy a Kubernetes-based platform using only Cloud Native and open-source technologies.

Following the steps below, you can create your own Kubernetes-based platform in a matter of minutes.

This is what you get:

- Hetzner Cloud k3s cluster, using kube-hetzner 🚀
  - Traefik ingress controller 🚦
  - cert-manager for TLS certificates 🔒
- Argo CD for GitOps 🐙
- Sealed Secrets for secrets management 🤐
- Keel for automatic image updates 🔄

# Create Your Own Platform!

## Get the Configuration

**1.** Fork this repository.

**1.** Run the script `./scripts/clean.sh` to get a base version of the platform:

```bash
./scripts/clean.sh
```

**1.** Create a Hetzner Cloud project, and get an API token with read/write access.
You will use this token later.

```bash
hcloud context create platform
```

## Option 1: Local Terraform

**1.** Install [Terraform](https://developer.hashicorp.com/terraform/install) and [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).

**1.** Remove the entire `.github` folder from the repository:

```bash
rm -rf .github
```

Put your Hetzner Cloud API token in a file name `terraform.tfvars` under the `terraform` folder:

```hcl
# terraform/terraform.tfvars
hcloud_token = "<my api token>"
```

**1.** Create an ED25519 SSH key pair and save them in the `terraform/terraform.tfvars` file:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/my-platform
cat ~/.ssh/my-platform.pub # public key
cat ~/.ssh/my-platform # private key
```

```hcl
# terraform/terraform.tfvars
hcloud_token = "<my api token>"
ssh_public_key = "<public key>"
ssh_private_key = <<EOF
---BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
EOF
```

**1.** Generate the VM images for the Hetzner Cloud cluster:

```bash
export HCLOUD_TOKEN=<my api token>
./scripts/packer.sh
```

**1.** Run Terraform to create the Hetzner Cloud cluster:

```bash
cd terraform
terraform init
terraform apply
```

**1.** Get the kubeconfig file from the Terraform output:

```bash
terraform output -raw kubeconfig > /tmp/hetzner-kubeconfig
```

See [Configure access via kubectl](#configure-access-via-kubectl) for more details.

## Option 2: Terraform Cloud

**1.** Sign up for Terraform Cloud (free), and create a project named `platform`.
Terraform Cloud username/organization should be the same as your GitHub username/organization.
If not, you will need to edit `.github/workflows/deploy.yml` to use the correct organization.

**1.** Save your Hetzner Cloud API token as both GitHub secret named `HCLOUD_TOKEN`
and as a Terraform Cloud variable with name `hcloud_token`.

**1.** Get API token from Terraform Cloud and save as GitHub secret with name `TF_API_TOKEN`.

**1.** Create an ED25519 SSH key pair and save them as the two Terraform Cloud variables `ssh_public_key` and `ssh_private_key`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/my-platform
cat ~/.ssh/my-platform.pub # public key
cat ~/.ssh/my-platform # private key
```

**1.** Push to `master`, triggering GitHub Actions to build and deploy the platform using Packer, Terraform and Argo CD.
Remember to enable GitHub Actions for your forked repository.

## Next steps

### Configure access via kubectl

```bash
cd terraform

# Method 1: overwrite default kubeconfig
# WARNING: this will overwrite your existing kubeconfig file
terraform output -raw kubeconfig > /tmp/hetzner-kubeconfig

# Method 2: merge with existing kubeconfig
terraform output -raw kubeconfig > /tmp/hetzner-kubeconfig
export KUBECONFIG=~/.kube/config:/tmp/hetzner-kubeconfig
kubectl config view --flatten > ~/.kube/config

kubectl config use-context k3s
```

If you are using Terraform Cloud, you will need to authenticate against Terraform Cloud with the following command:

```bash
terraform login
```

### Configure Traefik to use your domain

**1.** Buy a domain.

**1.** Create a DNS A record pointing to the external IP address(es) of Traefik's load balancer using your domain registrar.
You can get the external IP address(es) with the following command:

```bash
kubectl -n traefik get service traefik -o wide
```

**1.** Wait for the DNS record to propagate.

#### Caveats

Since we are using Klipper for load-balancing, you may get multiple IP addresses (one for each node).
If you have multiple IPs, create mulitple A records for your domain ([round-robin DNS](https://www.cloudflare.com/learning/dns/glossary/round-robin-dns)).

If you want to have only one IP address, configure kube-hetzner to use a Hetzner Load Balancer instead of Klipper (more expensive).

### Access Argo CD

After DNS propagation, you can access Argo CD at `https://argocd.example.com` (replace `example.com` with your domain given to `./scripts/clean.sh` earlier).

#### Access Argo CD via port forwarding to localhost

If you want to access Argo CD before DNS propagation, you can use port forwarding:

```bash
# Make Argo CD server accessible on localhost
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

**1.** Open Argo CD in your browser at `https://localhost:8080`.

**1.** To log in, use the username `admin` and the password stored in the secret `argocd-initial-admin-secret` in the `argocd` namespace.

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

# Deploy applications

Any folder created under `manifests/applications/` will create a new Argo CD application.
Any Kubernetes manifests (i.e. yaml) placed under `manifests/applications/<app-name>/` will be deployed to the cluster.

Example:

```bash
mkdir -p manifests/applications/my-app

cat <<EOF > manifests/applications/my-app/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: my-app
spec:
    containers:
    - name: nginx
      image: nginx:latest
EOF
```

# Deploy cluster-addons (Helm charts)

The same pattern is used for cluster-addons, however, we usually create an umbrella chart for the cluster-addons.
See the `manifests/cluster-addons` folder for examples.

# License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.
