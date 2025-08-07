# Build and deploy weather API to AKS (PowerShell version)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Reset = "`e[0m"

Write-Host "${Green}Building and deploying Weather API to AKS${Reset}"

# Check if required tools are installed
$requiredTools = @("az", "kubectl", "docker")
foreach ($tool in $requiredTools) {
    if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "${Red}$tool is required but not installed.${Reset}"
        exit 1
    }
}

# Get Terraform outputs
Push-Location terraform
$RESOURCE_GROUP = terraform output -raw resource_group_name
$CLUSTER_NAME = terraform output -raw kubernetes_cluster_name
$ACR_SERVER = terraform output -raw acr_login_server
Pop-Location

Write-Host "${Yellow}Using:${Reset}"
Write-Host "   Resource Group: $RESOURCE_GROUP"
Write-Host "   Cluster: $CLUSTER_NAME"
Write-Host "   ACR: $ACR_SERVER"

# Login to ACR
Write-Host "${Yellow}Logging into ACR...${Reset}"
az acr login --name $ACR_SERVER

# Build and push Docker image
Write-Host "${Yellow}Building Docker image...${Reset}"
docker build -t "$ACR_SERVER/weather-api:latest" .

Write-Host "${Yellow}📤 Pushing image to ACR...${Reset}"
docker push "$ACR_SERVER/weather-api:latest"

# Get AKS credentials
Write-Host "${Yellow}Getting AKS credentials...${Reset}"
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Update deployment file with ACR image
Write-Host "${Yellow}Updating deployment with ACR image...${Reset}"
(Get-Content k8s/deployment.yaml) -replace "your-acr.azurecr.io", $ACR_SERVER | Set-Content k8s/deployment.yaml

# Apply Kubernetes manifests
Write-Host "${Yellow}⚓ Deploying to Kubernetes...${Reset}"
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml

# Wait for deployment
Write-Host "${Yellow}⏳ Waiting for deployment to be ready...${Reset}"
kubectl rollout status deployment/weather-api

# Show status
Write-Host "${Green}Deployment completed!${Reset}"
Write-Host "${Yellow}Current status:${Reset}"
kubectl get pods -l app=weather-api
kubectl get services weather-api-service

Write-Host "${Green}Weather API is now running on AKS!${Reset}"
Write-Host "${Yellow}To test the API:${Reset}"
Write-Host "   kubectl port-forward service/weather-api-service 8080:80"
Write-Host "   curl http://localhost:8080/weather/London"
