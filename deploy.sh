#!/bin/bash

# Build and deploy weather API to AKS
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building and deploying Weather API to AKS${NC}"

# Check if required tools are installed
command -v az >/dev/null 2>&1 || { echo -e "${RED}❌ Azure CLI is required but not installed.${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is required but not installed.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is required but not installed.${NC}" >&2; exit 1; }

# Get Terraform outputs
cd terraform
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)
ACR_SERVER=$(terraform output -raw acr_login_server)
cd ..

echo -e "${YELLOW}📋 Using:${NC}"
echo -e "   Resource Group: ${RESOURCE_GROUP}"
echo -e "   Cluster: ${CLUSTER_NAME}"
echo -e "   ACR: ${ACR_SERVER}"

# Login to ACR
echo -e "${YELLOW}🔐 Logging into ACR...${NC}"
az acr login --name ${ACR_SERVER}

# Build and push Docker image
echo -e "${YELLOW}🏗️  Building Docker image...${NC}"
docker build -t ${ACR_SERVER}/weather-api:latest .

echo -e "${YELLOW}📤 Pushing image to ACR...${NC}"
docker push ${ACR_SERVER}/weather-api:latest

# Get AKS credentials
echo -e "${YELLOW}🔑 Getting AKS credentials...${NC}"
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --overwrite-existing

# Update deployment file with ACR image
echo -e "${YELLOW}📝 Updating deployment with ACR image...${NC}"
sed -i "s|your-acr.azurecr.io|${ACR_SERVER}|g" k8s/deployment.yaml

# Apply Kubernetes manifests
echo -e "${YELLOW}⚓ Deploying to Kubernetes...${NC}"
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml

# Wait for deployment
echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl rollout status deployment/weather-api

# Show status
echo -e "${GREEN}✅ Deployment completed!${NC}"
echo -e "${YELLOW}📊 Current status:${NC}"
kubectl get pods -l app=weather-api
kubectl get services weather-api-service

echo -e "${GREEN}🎉 Weather API is now running on AKS!${NC}"
echo -e "${YELLOW}💡 To test the API:${NC}"
echo -e "   kubectl port-forward service/weather-api-service 8080:80"
echo -e "   curl http://localhost:8080/weather/London"
