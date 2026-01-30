# vks-github-actions #
This repository is for the demostration of github actions with VKS 

Offical Documentation:- 
- [https://docs.github.com/en/actions/tutorials/use-actions-runner-controller/quickstart]

Helm Installation:- 
- [https://helm.sh/docs/intro/install/]

## Software Requirements:- ### 

- Running VKS Cluster
- Helm installation
- Any Code Editor of choice
- Github Token / Application ID
- kubectl

## Installing the Action Runner Controller ##

## Actions Runner Controller is a Kubernetes controller that manages self-hosted GitHub Actions runners as Kubernetes pods ###

> NAMESPACE="arc-systems"

> helm install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

###### To Download the above helm chart for offline install and edit values.yaml file #######

> helm pull oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

> kubectl get pods -n arc-systems                                                                                                                                                                                                      kube gihub-login:github-runner/github-actions root@globalmachine 10:03:25
NAME                                     READY   STATUS    RESTARTS   AGE
arc-gha-rs-controller-565c8dcd98-txz9m   1/1     Running   0          8m52s

### Create a Personal Access Token from the Github UI We can also do it from Github App ####

### Install the Gitlab runners ####

INSTALLATION_NAME="arc-runner-vks"  # This name will be referenced while running jobs
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/abc/vks-github-actions.git"
GITHUB_PAT="<PAT>"

> helm install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
  --set githubConfigSecret.github_token="${GITHUB_PAT}" \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set