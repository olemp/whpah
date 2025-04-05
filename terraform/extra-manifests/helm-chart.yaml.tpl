apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: argocd
  namespace: argocd
spec:
  repo: https://argoproj.github.io/argo-helm
  chart: argo-cd
  targetNamespace: argocd
  valuesContent: |-
    global:
      domain: argocd.bakseter.net

      networkPolicy:
        create: true

    configs:
      repositories:
        argocd:
          url: https://github.com/bakseter/whpat

      dex:
        enabled: false
