#!/bin/bash

set -e

echo "Setting AKS credentials..."
# mkdir $HOME/.kube
AKS_CLUSTER_NAME=$(terraform output cluster_name)
AKS_CLUSTER_RG=$(terraform output cluster_rg)

az aks get-credentials -n $AKS_CLUSTER_NAME -g $AKS_CLUSTER_RG --admin --overwrite-existing

echo "Creating service account and cluster role binding for Tiller..."
kubectl apply -f helm-rbac.yaml

echo "Initializing Helm..."
helm init --service-account tiller
echo "Helm has been installed."

echo "Installing KEDA components..."
kubectl apply -f keda.yaml --namespace keda
echo "KEDA components have been installed."

echo "Installing AAD Pod Identity components..."
if [[ -z $(kubectl get namespace podidentity 2>/dev/null) ]]
then
    kubectl create namespace podidentity
fi
kubectl apply -f aad-pod-identity.yaml --namespace podidentity
echo "AAD Pod Identity components have been installed."