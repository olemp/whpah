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

**1.** Fork this repository.

**2.** Run the script `./scripts/clean.sh` to get a base version of the platform:

```bash
./scripts/clean.sh
```

**3.** Create project `platform` in Hetzner Cloud and workspace `platform` in Terraform Cloud.
Terraform Cloud username/organization should be the same as your GitHub username/organization.

**4.** Run this command to create a Hetzner Cloud context for the project (required Hetzner CLI):

```bash
hcloud context create platform
```

**5.** Get API token from Hetzner Cloud with read/write access, and save as both GitHub secret named `HCLOUD_TOKEN`
and as a Terraform Cloud variable with name `hcloud_token`.

**6.** Get API token from Terraform Cloud and save as GitHub secret with name `TF_API_TOKEN`.

**7.** Create an ED25519 SSH key pair and save them as the two Terraform Cloud variables `ssh_public_key` and `ssh_private_key`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/my-platform
cat ~/.ssh/my-platform.pub # public key
cat ~/.ssh/my-platform # private key
```

**8.** Push to `master`, triggering GitHub Actions to build and deploy the platform using Packer, Terraform and Argo CD.

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

### Configure Traefik to use your domain

**1.** Buy a domain.

**2.** Create a DNS A record pointing to the load balancer IP address of your cluster using your domain registrar.
You can get the IP address with the following command:

```bash
kubectl -n traefik get service traefik -o wide
```

**3.** Wait for the DNS record to propagate.

### Access Argo CD

After DNS propagation, you can access Argo CD at `https://argocd.example.com` (replace `example.com` with your domain given to `./scripts/clean.sh` earlier).

#### Access Argo CD via port forwarding to localhost

If you want to access Argo CD before DNS propagation, you can use port forwarding:

```bash
# Make Argo CD server accessible on localhost
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

**3.** Open Argo CD in your browser at `https://localhost:8080`.

To log in, use the username `admin` and the password stored in the secret `argocd-initial-admin-secret` in the `argocd` namespace.

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
