# vks-github-actions

This repository demonstrates how to run **GitHub Actions self-hosted runners on a VKS (Kubernetes) cluster** using **Actions Runner Controller (ARC)**.

The setup uses **Helm** to deploy the controller and dynamically scale GitHub Actions runners as Kubernetes pods.

---

##  References

- **GitHub Actions Runner Controller (Official Docs)**  
  https://docs.github.com/en/actions/tutorials/use-actions-runner-controller/quickstart

- **Helm Installation Guide**  
  https://helm.sh/docs/intro/install/

---

##  Architecture Overview

High-level flow:
1. A GitHub Actions workflow is triggered
2. Actions Runner Controller detects the job
3. A runner pod is created in Kubernetes
4. The job executes inside the pod
5. The pod is deleted after job completion

---

##  Prerequisites

Ensure the following are available before proceeding:

- A running VKS Kubernetes cluster
- Helm (v3+)
- kubectl configured to access the cluster
- GitHub Personal Access Token (PAT) or GitHub App credentials
- Any code editor (VS Code, Vim, etc.)

---

## Installing Actions Runner Controller

Actions Runner Controller (ARC) is a Kubernetes controller that manages **self-hosted GitHub Actions runners** as ephemeral Kubernetes pods.

### Install Action Runner Comtroller 

```bash
NAMESPACE="arc-systems"

Step 1: Install ARC using Helm

helm install arc \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

Step 2: Verify Controller Pods

kubectl get pods -n arc-systems


(Optional) Download Helm Chart for Offline Installation

helm pull oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

## Installing GitHub Actions Runners

```bash

Step 1: GitHub Authentication

You must authenticate ARC with GitHub using one of the following:

GitHub Personal Access Token (PAT) or GitHub App

Step 2: Define Environment Variables

INSTALLATION_NAME="arc-runner-vks"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/abc/vks-github-actions"
GITHUB_PAT="<YOUR_GITHUB_PAT>"


Step 3: Install Runner Scale Set

helm install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
  --set githubConfigSecret.github_token="${GITHUB_PAT}" \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set


This creates a runner scale set that:

- Automatically scales runners based on workload
- Creates ephemeral runner pods
- Deletes runners after job completion
```