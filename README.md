# vks-github-actions

This repository provides a comprehensive guide and automation for provisioning a VMware Kubernetes Service (VKS) cluster and deploying applications using GitHub Actions. It leverages self-hosted runners on an existing Kubernetes cluster, managed by the Actions Runner Controller (ARC), to orchestrate the entire lifecycle of a VKS workload cluster.

The core of this repository is a GitHub Actions workflow that automates:
*   Provisioning a new VKS workload cluster.
*   Verifying the health and readiness of cluster nodes.
*   Installing essential addons like `cert-manager` and `contour`.
*   Cleaning up resources automatically upon failure, with manual approval gates.

## Prerequisites

Before you begin, ensure you have the following:

*   An existing Kubernetes cluster (e.g., a VKS Supervisor Cluster) to host the GitHub Actions runners.
*   `helm` (v3+) installed on your local machine.
*   `kubectl` configured to access your host Kubernetes cluster.
*   A GitHub Personal Access Token (PAT) with `repo` scope to allow ARC to register runners.
*   Credentials for the VKS Supervisor Cluster (`VCF_CLI_VSPHERE_PASSWORD` stored as a GitHub secret).

## Architecture

The system operates on a two-tiered Kubernetes structure:
1.  **Host Cluster**: An existing Kubernetes cluster where the Actions Runner Controller (ARC) is installed. This cluster hosts the ephemeral runner pods.
2.  **Workload Cluster**: A new VKS cluster that is dynamically created and configured by the GitHub Actions workflow running on the host cluster.

The workflow follows these steps:
1.  A GitHub Actions workflow is triggered (e.g., by a push to `main`).
2.  ARC, running in the host cluster, detects the job and provisions a runner pod.
3.  Inside the runner pod, `vcf-cli` and `kubectl` are used to connect to the VKS Supervisor.
4.  A new VKS workload cluster is created using the `clustercreate.yaml` manifest.
5.  Helper scripts monitor the status of the new cluster's nodes and pods.
6.  Once the cluster is ready, `cert-manager` and `contour` addons are installed.
7.  After the job completes, the runner pod is automatically terminated by ARC.

## Setting Up Self-Hosted Runners with ARC

To run the workflows in this repository, you must first set up the Actions Runner Controller (ARC) and a runner scale set in your host Kubernetes cluster.

### 1. Install Actions Runner Controller

ARC is a Kubernetes controller that automates the management of self-hosted runner pods.

```bash
# Define the namespace for the controller
NAMESPACE="arc-systems"

# 1. Install ARC using the official Helm chart
helm install arc \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

# 2. Verify that the controller pods are running
kubectl get pods -n "${NAMESPACE}"
# NAME                                                              READY   STATUS    RESTARTS   AGE
# arc-gha-runner-scale-set-controller-64cc9f45f9-z8h2b   1/1     Running   0          60s
```

### 2. Install the Runner Scale Set

The runner scale set defines how runner pods are created and scaled. It connects to your GitHub repository and listens for new jobs.

```bash
# 1. Define your configuration
INSTALLATION_NAME="arc-runner-vks"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/saurabhtandon13/vks-github-actions"
GITHUB_PAT="<YOUR_GITHUB_PAT>" # Replace with your GitHub Personal Access Token

# 2. Install the runner scale set using Helm
helm install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
  --set githubConfigSecret.github_token="${GITHUB_PAT}" \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```
This creates a runner scale set named `arc-runner-vks`. When a job in this repository requires a runner with the label `arc-runner-vks`, ARC will automatically create a pod in the `arc-runners` namespace to execute it.

## Workflow Automation (`.github/workflows/main.yaml`)

The `main.yaml` workflow orchestrates the entire cluster lifecycle. It is designed to be modular, with distinct jobs for each major task.

### Workflow Jobs

| Job Name                        | Description                                                                                                                              | Key Dependencies               |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `Downloading-Plugin`             | Downloads and caches `kubectl` and `vcf-cli` binaries for subsequent jobs.                                                               | -                              |
| `Workload-Creation`              | Connects to the VKS Supervisor and applies `clustercreate.yaml` to provision the new workload cluster.                                     | `Downloading-Plugin`           |
| `Checking-Cluster-Status`        | Uses the `machine-status.sh` script to poll the workload cluster's machines until they are all in a 'Ready' state.                         | `Workload-Creation`            |
| `AddOn-Installation-Cert-Manager`| Installs the `cert-manager` addon and uses `pod-status-check.sh` to verify that its pods are running.                                      | `Checking-Cluster-Status`      |
| `AddOn-Installation-Contour`     | Installs the `contour` addon (as a LoadBalancer) and uses `pod-status-check.sh` to verify its pods are running.                            | `Checking-Cluster-Status`      |
| `Cluster-Status`                 | A simple final job to confirm successful completion of the workflow.                                                                     | `AddOn-Installation-Cert-Manager` |
| `Clean-up-Cluster`               | **(On Failure)** Triggers if cluster creation fails. Deletes the cluster after manual approval.                                          | `Workload-Creation` or `Checking-Cluster-Status` |
| `Clean-up-Addons`                | **(On Failure)** Triggers if addon installation fails. Deletes the addons after manual approval.                                         | `AddOn-Installation-*` jobs    |

### Environment Variables
The workflow uses global environment variables defined at the top of `main.yaml` to configure the cluster. These should be adjusted to match your environment.

```yaml
env:
  SUPERVISOR_IP: "xxx.xxx.xxx.xxx"
  VCF_CLI_VSPHERE_USERNAME: "sample@example.com"
  VCF_CLI_VSPHERE_PASSWORD: ${{ secrets.VCF_CLI_VSPHERE_PASSWORD }}
  WORKLOAD_CLUSTER_NAME: "sample"
  VSPHERE_NAMESPACE: "example"
```

## Repository Components

### Cluster and Addon Manifests

*   **`clustercreate.yaml`**: A Cluster API manifest that defines the VKS workload cluster. It specifies the Kubernetes version, control plane and worker node configurations, CNI/CSI settings, and VM classes. The workflow dynamically replaces `WORKLOAD_CLUSTER_NAME` and `VSPHERE_NAMESPACE` placeholders in this file.

*   **`addons/cert-manager/addon-cert-manager.yaml`**: Manifest to install the `cert-manager` addon on the newly created workload cluster.

*   **`addons/contour/addon-contour.yaml`**: Manifests to install the `contour` addon and configure its Envoy service as type `LoadBalancer`.

### Helper Scripts

*   **`scripts/machine-status.sh`**: A robust shell script that polls the status of `Machine` objects in the specified namespace. It waits until all machines prefixed with the workload cluster name report a `Ready` condition or until a timeout is reached. This ensures the workflow proceeds only after the cluster infrastructure is fully provisioned.

*   **`scripts/pod-status-check.sh`**: A script that polls all pods in a given namespace until they reach the `Running` state. It's used after addon installations to confirm that the components are healthy before the workflow continues.
