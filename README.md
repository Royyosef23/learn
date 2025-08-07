# Weather API on Azure Kubernetes Service (AKS)

A cost-effective weather API service deployed on Azure Kubernetes Service using Terraform and best practices.

## 🏗️ Architecture

- **Application**: Flask-based weather API
- **Container**: Docker with multi-stage build
- **Orchestration**: Azure Kubernetes Service (AKS)
- **Infrastructure**: Terraform for IaC
- **Registry**: Azure Container Registry (ACR)

## 💰 Cost Optimization Features

- **Free AKS Tier**: No cluster management fees
- **Burstable VMs**: Standard_B2s instances for variable workloads
- **Auto-scaling**: Scale down to 1 node when not in use
- **Basic ACR**: Cheapest container registry tier
- **Kubenet**: Cost-effective networking plugin
- **Resource Limits**: Prevent resource waste

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** - [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
3. **kubectl** - [Install kubectl](https://kubernetes.io/docs/tasks/tools/)
4. **Docker** - [Install Docker](https://docs.docker.com/get-docker/)

### 1. Setup Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your Subscription Name"
```

### 2. Get Weather API Key

1. Sign up at [OpenWeatherMap](https://openweathermap.org/api)
2. Get your free API key
3. Update the secret:

```bash
# Encode your API key
echo -n "your-actual-api-key" | base64

# Update k8s/secret.yaml with the encoded key
```

### 3. Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### 4. Deploy Application

```bash
# Using PowerShell (Windows)
.\deploy.ps1

# Or using Bash (Linux/Mac/WSL)
chmod +x deploy.sh
./deploy.sh
```

### 5. Test the API

```bash
# Port forward to access the service
kubectl port-forward service/weather-api-service 8080:80

# Test the API
curl "http://localhost:8080/weather/London"
curl "http://localhost:8080/weather/Tel%20Aviv"
curl "http://localhost:8080/health"
```

## 📊 Monitoring and Management

### Check Application Status

```bash
# Check pods
kubectl get pods -l app=weather-api

# Check service
kubectl get service weather-api-service

# Check logs
kubectl logs -l app=weather-api --tail=50

# Describe pod for troubleshooting
kubectl describe pod -l app=weather-api
```

### Scaling

```bash
# Scale manually
kubectl scale deployment weather-api --replicas=3

# Check HPA (if configured)
kubectl get hpa
```

### Updates

```bash
# Update image
kubectl set image deployment/weather-api weather-api=your-acr.azurecr.io/weather-api:v2

# Check rollout status
kubectl rollout status deployment/weather-api

# Rollback if needed
kubectl rollout undo deployment/weather-api
```

## 🛡️ Security Best Practices

- ✅ Non-root container user
- ✅ Resource limits and requests
- ✅ Secrets management
- ✅ Health checks
- ✅ RBAC enabled
- ✅ Managed identity for AKS-ACR access

## 💡 Cost Management Tips

1. **Monitor Usage**: Use Azure Cost Management
2. **Auto-shutdown**: Consider auto-shutdown for dev environments
3. **Reserved Instances**: For production workloads
4. **Spot Instances**: Enable for non-critical workloads
5. **Right-sizing**: Monitor and adjust VM sizes

## 🧹 Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Destroy infrastructure
cd terraform
terraform destroy
```

## 📝 API Endpoints

- `GET /health` - Health check
- `GET /weather/<city>` - Get weather for specific city
- `GET /weather?city=<city>` - Get weather with query parameter

### Example Responses

```json
{
  "city": "London",
  "country": "GB",
  "temperature": 15.3,
  "description": "light rain",
  "humidity": 82,
  "timestamp": "2025-08-06T10:30:00"
}
```

## 🐛 Troubleshooting

### Common Issues

1. **Pod not starting**: Check logs with `kubectl logs`
2. **Image pull errors**: Verify ACR access and image name
3. **API key issues**: Ensure secret is properly base64 encoded
4. **Network issues**: Check service and ingress configuration

### Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# Check node status
kubectl get nodes

# Check all resources
kubectl get all

# Describe problematic resources
kubectl describe pod <pod-name>
```

## 📚 Learning Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
