#!/bin/sh
#Variables
CLUSTER_NAME="kjadeja-small-cluster"
MACHINE_TYPE="e2-standard-8"
NUM_NODES="5"
MONITORING_NS="monitoring"
DOCKER_ID="jadejakajal13"
DOCKER_API="b461d1b4-82c4-499e-afc0-f17943a16411"
DOCKER_EMAIL="jadejakajal13@gmail.com"
VOLT_DEPLPOYMENTNAME="mydb"
PROPERTY_FILE="myproperties.yaml"
K8S_CLUSTER_VERSION="1.25.15-gke.1115000"
LICENSE_FILE="/Users/tesla/Documents/dev_license.xml"
add_helm_repo=true

if [ "$add_helm_repo" = true ]; then
    echo "Adding Helm repositories..."
    helm repo add voltdb https://voltdb-kubernetes-charts.storage.googleapis.com
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

    helm repo update
    echo "Helm repositories added and updated."
else
    echo "No action needed. Variable add_helm_repo is set to false."
fi
#creating a cluster

gcloud container clusters create $CLUSTER_NAME --machine-type $MACHINE_TYPE  --num-nodes $NUM_NODES  \
 --cluster-version $K8S_CLUSTER_VERSION \
 --provisioning-model=SPOT  \
 --labels=user=$DOCKER_ID  

#creating namespaces

kubectl create namespace $MONITORING_NS

#creating docker secret
kubectl create secret docker-registry dockerio-registry --docker-username=$DOCKER_ID \
--docker-password=$DOCKER_API  --docker-email=$DOCKER_EMAIL

kubectl get ns 

helm install monitoring-stack prometheus-community/kube-prometheus-stack --version=30.0.1 -f prom_config.yaml -n $MONITORING_NS

helm install $VOLT_DEPLPOYMENTNAME voltdb/voltdb --wait --values $PROPERTY_FILE \
 --set-file cluster.config.licenseXMLFile=$LICENSE_FILE \
 --set cluster.config.deployment.metrics.enabled=true \
 --set cluster.serviceSpec.perpod.metrics.enabled=true \
 --set cluster.serviceSpec.service.metrics.type=ClusterIP
