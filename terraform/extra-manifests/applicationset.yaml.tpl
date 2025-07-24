apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: root
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ['missingkey=error']
  generators:
    - git:
        repoURL: https://github.com/olemp/whpah.git
        revision: HEAD
        directories:
          - path: manifests/applications/**
          - path: manifests/cluster-addons/**
  template:
    metadata:
      name: '{{.path.basename}}'
      labels:
        app.kubernetes.io/component: '{{if eq (index .path.segments 1) "applications"}}app{{else}}addon{{end}}'
    spec:
      project: default
      sources:
        - repoURL: https://github.com/olemp/whpah.git
          targetRevision: HEAD
          path: '{{.path.path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.path.basename}}'
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
