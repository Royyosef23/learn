# Weather API on Azure Kubernetes Service (AKS)

## Project Overview

This project implements a production-ready weather API service deployed on Azure Kubernetes Service (AKS) using Infrastructure as Code (Terraform) principles. The architecture follows cloud-native best practices with automated CI/CD pipelines, comprehensive testing, and cost optimization strategies.

## Prerequisites and Installation Requirements

### Required Software Components

#### Azure CLI
**Purpose**: Command-line interface for Azure resource management
**Installation**: Download from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
**Configuration**: Execute `az login` for authentication
**Version Requirement**: Latest stable version recommended

#### Terraform
**Purpose**: Infrastructure as Code provisioning and management
**Installation**: Download from https://learn.hashicorp.com/tutorials/terraform/install-cli
**Version Requirement**: >= 1.0 (specified in terraform configuration)
**Verification**: Execute `terraform --version` to confirm installation

#### kubectl
**Purpose**: Kubernetes cluster management and application deployment
**Installation**: Download from https://kubernetes.io/docs/tasks/tools/
**Configuration**: Automatic configuration via Azure CLI after AKS deployment
**Version Compatibility**: Must be compatible with deployed AKS version

#### Docker
**Purpose**: Container image building and local testing capabilities
**Installation**: Download from https://docs.docker.com/get-docker/
**Configuration**: Ensure Docker daemon is running
**Platform Support**: Available for Windows, macOS, and Linux

## Required Manual Configuration

### 1. Azure Service Principal Creation
You must create an Azure Service Principal for GitHub Actions authentication:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

### 2. OpenWeatherMap API Key Configuration
**Status**: CONFIGURED - API key is already encoded and set in k8s/secret.yaml

The OpenWeatherMap API key has been configured for this project:
1. Valid API key obtained from https://openweathermap.org/api
2. Key properly base64 encoded for Kubernetes secret
3. Secret configured in k8s/secret.yaml

**Note**: The API key is configured but not exposed in the repository for security purposes.

### 3. Terraform Variables File
Create terraform/terraform.tfvars with your specific configuration values:
```hcl
location = "West Europe"
tags = {
  Environment = "Development"
  Project     = "WeatherAPI"
  Owner       = "YourName"
}
```

### 4. GitHub Repository Secrets Configuration
Add the following secrets in GitHub repository settings:

**Azure Authentication**:
- ARM_CLIENT_ID: Service principal application ID
- ARM_CLIENT_SECRET: Service principal password
- ARM_SUBSCRIPTION_ID: Azure subscription identifier
- ARM_TENANT_ID: Azure tenant identifier
- AZURE_CREDENTIALS: Complete JSON output from service principal creation

**Container Registry** (configured automatically via Terraform):
- ACR_LOGIN_SERVER: Registry URL

**Note**: ACR authentication now uses managed identity exclusively for enhanced security.
No username/password credentials are needed or provided.

**AKS Configuration** (will be available after Terraform deployment):
- AKS_CLUSTER_NAME: Cluster name (output from Terraform)
- AKS_RESOURCE_GROUP: Resource group name (output from Terraform)

## Deployment Process

### Step 1: Initial Setup and Authentication
```bash
# Authenticate with Azure
az login

# Set subscription context (if multiple subscriptions available)
az account set --subscription "Your Subscription Name"

# Verify authentication
az account show
```

### Step 2: Infrastructure Deployment
```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform working directory
terraform init

# Validate configuration syntax
terraform validate

# Review planned infrastructure changes
terraform plan -var-file="terraform.tfvars"

# Apply infrastructure changes
terraform apply -var-file="terraform.tfvars"
```

### Step 3: Extract Infrastructure Information
```bash
# Get infrastructure outputs for GitHub secrets
terraform output aks_cluster_name
terraform output resource_group_name
terraform output acr_login_server

# Note: ACR now uses managed identity authentication
# No admin credentials needed - more secure than username/password
```

### Step 4: Configure Kubernetes Access
```bash
# Configure kubectl with AKS credentials
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>

# Verify cluster connectivity
kubectl cluster-info

# Check node status
kubectl get nodes
```

### Step 5: Update GitHub Secrets
Add the infrastructure outputs to GitHub repository secrets (see Required Manual Configuration section).

### Step 6: Deploy Application
Commit and push changes to trigger CI/CD pipeline:
```bash
git add .
git commit -m "Deploy weather API"
git push origin dev  # For development environment
git push origin main # For production environment
```

### Step 7: Verify Deployment
```bash
# Port forward to access service locally
kubectl port-forward service/weather-api-service 8080:80

# Test deployed application
curl "http://localhost:8080/weather/London"
curl "http://localhost:8080/weather/Tel%20Aviv"
curl "http://localhost:8080/health"
```

## Technical Architecture

### Application Layer
- **Framework**: Flask (Python) - Lightweight WSGI web application framework
- **API Design**: RESTful endpoints with JSON responses
- **External Integration**: OpenWeatherMap API for weather data
- **Health Monitoring**: Built-in health check endpoint for Kubernetes probes
- **Error Handling**: Comprehensive exception handling with appropriate HTTP status codes

### Containerization
- **Base Image**: Multi-stage Docker build for optimized image size
- **Security**: Non-root user execution within container
- **Port Configuration**: Application runs on port 5000, exposed via Kubernetes service on port 80
- **Environment Variables**: Secure API key injection via Kubernetes secrets

### Orchestration Platform
- **AKS Cluster**: Managed Kubernetes service on Azure
- **Node Configuration**: Standard_B2s burstable VMs for cost efficiency
- **Scaling**: Horizontal Pod Autoscaler and Cluster Autoscaler configured
- **Networking**: Kubenet plugin for simplified and cost-effective networking
- **Load Balancing**: Azure Load Balancer integrated with Kubernetes services

### Infrastructure as Code
- **Terraform**: Infrastructure provisioning and management
- **State Management**: Remote state storage capability
- **Resource Organization**: Logical grouping with Azure Resource Groups
- **Tagging Strategy**: Consistent resource tagging for cost tracking and management

### Container Registry
- **Azure Container Registry (ACR)**: Private registry for Docker images
- **Integration**: Seamless integration with AKS via managed identity
- **Security**: Role-based access control (RBAC) for image pulling

## Cost Optimization Architecture

### Infrastructure Costs
- **AKS Management**: Free tier eliminates cluster management fees
- **Compute Resources**: Burstable VM instances (Standard_B2s) scale based on demand
- **Storage**: Premium SSD with minimal 30GB allocation
- **Network**: Standard Load Balancer included with AKS
- **Registry**: Basic tier ACR with 10GB included storage

### Auto-scaling Configuration
- **Cluster Autoscaler**: Scales nodes from 1 to 3 based on pod resource requirements
- **Horizontal Pod Autoscaler**: Scales application pods based on CPU/memory utilization
- **Resource Limits**: Prevents resource waste through defined requests and limits

### Cost Management Strategy

#### Resource Optimization
- Burstable VM instances adapt to workload demands
- Autoscaling reduces costs during low usage periods
- Basic tier services minimize operational expenses

#### Budget and Alert Configuration
**Azure Budget Setup**:
```bash
# Create monthly budget with alert
az consumption budget create \
  --budget-name "weather-api-monthly-budget" \
  --amount 100 \
  --category Cost \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --notifications '[{
    "enabled": true,
    "operator": "GreaterThan",
    "threshold": 80,
    "contactEmails": ["your-email@domain.com"],
    "thresholdType": "Actual"
  }]'
```

**Cost Monitoring Commands**:
```bash
# Monitor current month costs
az consumption usage list \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date +%Y-%m-%d) \
  --output table

# Get cost breakdown by service
az consumption usage list \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date +%Y-%m-%d) \
  --include-meter-details \
  --output json | jq '.[] | {service: .meterDetails.meterCategory, cost: .pretaxCost}'
```

#### Orphaned Resource Detection
**Weekly Resource Audit**:
```bash
# List all resources in resource group
az resource list --resource-group <resource-group-name> --output table

# Check for untagged resources
az resource list --resource-group <resource-group-name> \
  --query "[?tags==null]" --output table

# Identify resources without proper cost tracking
az resource list --resource-group <resource-group-name> \
  --query "[?!tags.Environment]" --output table
```

**Automated Monitoring Script** (recommended to run weekly):
```bash
#!/bin/bash
# weekly-audit.sh - Resource and cost monitoring script

RESOURCE_GROUP="<your-resource-group>"
DATE=$(date +%Y-%m-%d)

echo "=== Weekly Resource Audit - $DATE ==="

# Check for orphaned resources
echo "Checking for orphaned resources..."
az resource list --resource-group $RESOURCE_GROUP --output table

# Monitor this month's costs
echo "Current month cost summary..."
az consumption usage list \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date +%Y-%m-%d) \
  --output table

# Check node utilization
echo "Node utilization check..."
kubectl top nodes

# Verify autoscaler hasn't scaled unnecessarily
echo "Recent scaling events..."
kubectl get events --sort-by='.lastTimestamp' | grep -i scale | head -10
```

#### Monitoring and Alerting
- Azure Cost Management budget configuration
- Resource utilization tracking through Azure Monitor
- Automated scaling policies based on demand metrics
- Weekly cost reports and resource optimization recommendations

#### Development vs Production
- Shared infrastructure for development workloads
- Environment-specific scaling configurations  
- Cost allocation through comprehensive resource tagging
- Separate budgets for development and production environments

## Project Structure and Component Responsibilities

#### app.py
**Purpose**: Main application entry point and Flask web server
**Technical Details**:
- Defines REST API endpoints for weather data retrieval
- Implements health check endpoint for Kubernetes liveness/readiness probes
- Handles external API integration with OpenWeatherMap service
- Error handling and JSON response formatting
- Environment variable configuration for API key management

**Key Functions**:
- `/health` - Returns application status for monitoring systems
- `/weather/<city>` - Path parameter endpoint for weather queries
- `/weather?city=<city>` - Query parameter endpoint for weather queries

#### requirements.txt
**Purpose**: Python dependency specification file
**Contents**:
- Flask: Web framework
- requests: HTTP client library for external API calls
- Production-ready versions pinned for reproducible builds

#### Dockerfile
**Purpose**: Container image build instructions
**Technical Implementation**:
- Multi-stage build process for optimized image size
- Non-root user configuration for security compliance
- Port exposure configuration (5000)
- Working directory and file copy optimization
- Environment variable defaults

#### deploy.ps1 / deploy.sh
**Purpose**: Deployment automation scripts
**Functionality**:
- Azure Container Registry authentication
- Docker image building and tagging
- Image pushing to registry
- Kubernetes deployment updates
- Cross-platform support (PowerShell for Windows, Bash for Unix)

### Kubernetes Configuration (k8s/)

#### deployment.yaml
**Purpose**: Kubernetes Deployment resource definition
**Configuration Details**:
- Pod template specification with container configuration
- Resource requests and limits for proper scheduling
- Liveness and readiness probes for health monitoring
- Environment variable injection from secrets
- Rolling update strategy configuration
- Replica count and selector labels

**Resource Management**:
- CPU requests: 100m (0.1 CPU core)
- Memory requests: 128Mi
- CPU limits: 500m (0.5 CPU core)
- Memory limits: 256Mi

#### secret.yaml
**Purpose**: Sensitive data storage for API keys
**Security Implementation**:
- Base64 encoded values (not encryption, but obfuscation)
- Separate from application code for security
- Mounted as environment variables in pods

**Required Configuration**: You must update this file with your actual OpenWeatherMap API key:
```bash
echo -n "your-actual-api-key" | base64
```
Replace the encoded value in the secret.yaml file.

### Terraform Infrastructure (terraform/)

#### main.tf
**Purpose**: Primary infrastructure resource definitions
**Resources Defined**:

**Random Pet Resource**:
- Generates unique naming prefix for all resources
- Ensures no naming conflicts in Azure subscriptions

**Azure Resource Group**:
- Logical container for all project resources
- Location-based resource organization
- Tag-based cost tracking and management

**AKS Cluster Configuration**:
- DNS prefix for cluster identification
- SKU tier set to "Free" for cost optimization
- System-assigned managed identity for secure Azure resource access
- Kubenet networking plugin selection
- RBAC enablement for security

**Node Pool Configuration**:
- VM size: Standard_B2s (2 vCPU, 4GB RAM, burstable performance)
- OS disk: 30GB managed disk
- Autoscaling: min 1 node, max 3 nodes
- Virtual Machine Scale Sets for flexibility

**Azure Container Registry**:
- Basic tier for cost optimization
- **Admin access disabled** for enhanced security
- Authentication via managed identity only
- Integration with AKS via role assignment

**Role Assignment**:
- Grants AKS managed identity AcrPull permissions
- Enables seamless image pulling from ACR to AKS

#### variables.tf
**Purpose**: Input variable definitions for Terraform configuration
**Variables Defined**:
- location: Azure region for resource deployment
- tags: Common tags applied to all resources

#### terraform.tfvars
**Purpose**: Variable value assignments
**Configuration**: This file should be created as specified in the Required Manual Configuration section above.

#### outputs.tf
**Purpose**: Terraform output value definitions
**Outputs Provided**:
- Resource group name
- AKS cluster name
- ACR login server URL
- AKS credentials command for kubectl configuration

### CI/CD Pipeline (.github/workflows/)

#### ci-cd.yml
**Purpose**: Main continuous integration and deployment pipeline
**Workflow Triggers**:
- Push events to main and dev branches
- Pull requests targeting main branch

**Job Definitions**:

**Test Job**:
- Python 3.11 runtime environment
- Dependency installation from requirements.txt
- pytest execution with coverage reporting
- flake8 linting for code quality

**Build Job**:
- Depends on successful test completion
- Azure Container Registry authentication
- Docker image building with commit hash tagging
- Multi-tag strategy (latest for main, dev-prefixed for dev branch)
- Image pushing to ACR

**Deploy-Production Job**:
- Executes only for main branch commits
- Requires production environment approval
- Azure authentication via service principal
- AKS credential acquisition
- Kubernetes manifest deployment
- Rollout status verification

**Deploy-Development Job**:
- Executes for dev branch commits
- Development environment deployment
- Simplified deployment process for testing

#### infrastructure.yml
**Purpose**: Infrastructure deployment workflow
**Trigger**: Manual workflow dispatch with input parameters
**Operations Supported**:
- terraform plan: Preview infrastructure changes
- terraform apply: Deploy infrastructure changes
- terraform destroy: Remove infrastructure resources

**Environment Support**: Separate dev and prod environment configurations

### Testing Framework (tests/)

#### test_app.py
**Purpose**: Application unit and integration tests
**Test Coverage**:
- Health endpoint functionality verification
- Weather API endpoint testing with various input methods
- Error handling validation
- Response format verification

**Testing Strategy**:
- pytest framework utilization
- Flask test client for HTTP request simulation
- Configurable responses based on API key availability

## Alternative Deployment Methods

## Security Implementation

### Container Security
- Non-root user execution within containers
- Minimal base image selection
- No sensitive data in container images

### Kubernetes Security
- Resource limits prevent resource exhaustion attacks
- RBAC enabled for cluster access control
- Secrets management for sensitive configuration
- Health checks for application monitoring

### Azure Security
- Managed identity authentication eliminates credential storage
- Private container registry access
- Network security through Azure virtual networks
- Role-based access control for resource access

## Monitoring and Observability

### Application Monitoring
- Health check endpoints for Kubernetes probes
- Structured logging for debugging and troubleshooting
- HTTP status code compliance for proper error handling

### Infrastructure Monitoring
- Azure Monitor integration for cluster metrics
- Container insights for pod-level monitoring
- Cost tracking through resource tagging

### Deployment Monitoring
- GitHub Actions workflow status tracking
- Kubernetes rollout status verification
- Automated rollback capabilities on deployment failures

## Cost Management Strategy

### Resource Optimization
- Burstable VM instances adapt to workload demands
- Autoscaling reduces costs during low usage periods
- Basic tier services minimize operational expenses

### Monitoring and Alerting
- Azure Cost Management budget configuration
- Resource utilization tracking
- Automated scaling policies based on demand

### Development vs Production
- Shared infrastructure for development workloads
- Environment-specific scaling configurations
- Cost allocation through resource tagging

## Testing and Verification Procedures

### Local Application Testing
```bash
# Install Python dependencies
pip install -r requirements.txt

# Set environment variable for API key
export WEATHER_API_KEY="your-api-key"

# Run application locally
python app.py

# Test endpoints in separate terminal
curl http://localhost:5000/health
curl "http://localhost:5000/weather/London"
```

### Containerized Testing
```bash
# Build Docker image
docker build -t weather-api-test .

# Run container with API key
docker run -p 5000:5000 -e WEATHER_API_KEY="your-api-key" weather-api-test

# Test containerized application
curl http://localhost:5000/health
curl "http://localhost:5000/weather/Tokyo"
```

### Kubernetes Deployment Testing
```bash
# Port forward to access service locally
kubectl port-forward service/weather-api-service 8080:80

# Test deployed application
curl "http://localhost:8080/weather/London"
curl "http://localhost:8080/weather/Tel%20Aviv"
curl "http://localhost:8080/health"
```

### Automated Testing Suite
```bash
# Install testing dependencies
pip install pytest pytest-cov flake8

# Run unit tests
pytest tests/ -v

# Run tests with coverage report
pytest tests/ --cov=app --cov-report=html

# Execute linting checks
flake8 app.py
```

## Operational Management

### Application Status Monitoring
```bash
# Check pod status and health
kubectl get pods -l app=weather-api

# View detailed pod information
kubectl describe pod -l app=weather-api

# Access application logs
kubectl logs -l app=weather-api --tail=50

# Follow real-time logs
kubectl logs -l app=weather-api -f
```

### Service and Network Verification
```bash
# Check service configuration
kubectl get service weather-api-service

# View service details and endpoints
kubectl describe service weather-api-service

# Check ingress configuration (if applicable)
kubectl get ingress
```

### Scaling Operations
```bash
# Manual horizontal scaling
kubectl scale deployment weather-api --replicas=3

# Verify scaling operation
kubectl get pods -l app=weather-api

# Check Horizontal Pod Autoscaler status
kubectl get hpa

# View autoscaler details
kubectl describe hpa weather-api-hpa
```

### Application Updates and Rollbacks
```bash
# Update application image
kubectl set image deployment/weather-api weather-api=<acr-name>.azurecr.io/weather-api:v2

# Monitor rollout progress
kubectl rollout status deployment/weather-api

# View rollout history
kubectl rollout history deployment/weather-api

# Rollback to previous version
kubectl rollout undo deployment/weather-api

# Rollback to specific revision
kubectl rollout undo deployment/weather-api --to-revision=2
```

## Troubleshooting Guide

### Common Issues and Resolution

#### Pod Startup Failures
**Symptoms**: Pods stuck in Pending or CrashLoopBackOff state
**Diagnostic Commands**:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```
**Common Causes**:
- Insufficient cluster resources
- Image pull authentication failures
- Invalid environment variable configuration
- Health check failures

#### Image Pull Errors
**Symptoms**: ErrImagePull or ImagePullBackOff status
**Resolution Steps**:
1. Verify ACR authentication: `az acr login --name <acr-name>`
2. Check image existence: `az acr repository list --name <acr-name>`
3. Verify AKS-ACR role assignment in Terraform
4. Confirm image tag accuracy in deployment manifest

#### API Key Configuration Issues
**Symptoms**: Weather API returns authentication errors
**Resolution Steps**:
1. Verify API key validity at OpenWeatherMap
2. Confirm base64 encoding accuracy
3. Check secret deployment: `kubectl get secret weather-api-secret -o yaml`
4. Validate environment variable injection in pod

#### Network Connectivity Problems
**Symptoms**: Service unreachable or timeout errors
**Diagnostic Commands**:
```bash
kubectl get endpoints weather-api-service
kubectl describe service weather-api-service
kubectl get pods -o wide
```

#### Resource Exhaustion
**Symptoms**: Pod evictions or scheduling failures
**Monitoring Commands**:
```bash
kubectl top nodes
kubectl top pods
kubectl describe node <node-name>
```

### Performance Optimization

#### Resource Tuning
- Adjust CPU and memory requests based on actual usage patterns
- Configure appropriate resource limits to prevent resource starvation
- Monitor resource utilization through Azure Monitor or kubectl top

#### Scaling Configuration
- Fine-tune HPA metrics and thresholds
- Adjust cluster autoscaler parameters
- Consider vertical pod autoscaling for resource optimization

## Production Readiness and Optimization Considerations

### Security Enhancements for Production

#### Container Registry Security
**Current Implementation**: ACR with admin access **DISABLED** - using managed identity only
**Security Benefits**:
- **No static credentials** stored in GitHub secrets
- **Automatic credential rotation** managed by Azure
- **Principle of least privilege** - AKS gets only ACR pull permissions
- **Eliminates credential exposure risk** in logs or configuration files

**Authentication Methods Comparison**:

| Method | Security Level | Credential Management | Rotation | Recommended |
|--------|----------------|----------------------|----------|-------------|
| **Admin Username/Password** | LOW | Manual static secrets | Manual | NEVER |
| **Service Principal (SPN)** | MEDIUM | Manual secret rotation | Manual | OK for CI/CD |
| **Managed Identity** | HIGH | Automatic by Azure | Automatic | **Best Practice** |

**Implementation**:
```hcl
# In terraform/main.tf
resource "azurerm_container_registry" "main" {
  admin_enabled = false  # Security: No admin access
  # ... other configuration
}

# Role assignment for AKS managed identity
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
```
**Implementation**:
```hcl
# In terraform/main.tf
resource "azurerm_container_registry" "acr" {
  admin_enabled = false  # Change from true to false
  # ... rest of configuration
}
```

#### Secrets Management Evolution
**Current Implementation**: Kubernetes secrets in YAML files
**Production Recommendation**: Migrate to Azure Key Vault with CSI Secret Store Driver
**Benefits**:
- Centralized secret management
- Automatic secret rotation capabilities
- Enhanced audit logging
- Integration with Azure RBAC

**Implementation Steps**:
1. Install Azure Key Vault CSI Secret Store Driver
2. Create Azure Key Vault instance
3. Configure SecretProviderClass for weather API key
4. Update deployment to use mounted secrets

#### Docker Image Security
**Current Status**: Multi-stage build implemented
**Additional Recommendations**:
- Implement image vulnerability scanning in CI/CD pipeline
- Use specific base image tags instead of "latest"
- Remove development dependencies from production images
- Implement image signing for supply chain security

### Infrastructure Optimization and Monitoring

#### Cost Management Strategy
**Implement Azure Budgets**:
```bash
# Create budget alert for monthly spending
az consumption budget create \
  --budget-name "weather-api-budget" \
  --amount 100 \
  --time-grain Monthly \
  --start-date 2025-01-01 \
  --end-date 2025-12-31
```

**Resource Monitoring Commands**:
```bash
# List all created resources to identify orphaned resources
az resource list --resource-group <resource-group-name> --output table

# Monitor resource costs
az consumption usage list --start-date 2025-01-01 --end-date 2025-01-31
```

#### Autoscaling Optimization
**Current Configuration**: Cluster autoscaler (1-3 nodes)
**Monitoring Recommendations**:
- Track node utilization to prevent unnecessary scaling to maximum capacity
- Monitor autoscaler events: `kubectl get events --field-selector source=cluster-autoscaler`
- Set up alerts if cluster consistently scales to 3 nodes without justified load
- Review scaling metrics and thresholds regularly

**Cost Control for Autoscaling**:
```bash
# Monitor node utilization to justify scaling
kubectl top nodes

# Check autoscaler status and decisions
kubectl describe configmap cluster-autoscaler-status -n kube-system

# Review scaling events
kubectl get events --sort-by='.lastTimestamp' | grep -i scale
```

**Implement Vertical Pod Autoscaler (VPA) for memory optimization:**
- Configure appropriate scaling metrics and thresholds
- Prevent memory waste through intelligent resource allocation

**VPA Implementation**:
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: weather-api-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: weather-api
  updatePolicy:
    updateMode: "Auto"
```

#### Load Balancer Considerations
**Current Implementation**: Basic Load Balancer included with AKS (no additional cost)
**Future Enhancements**:
- Consider Application Gateway Ingress Controller (AGIC) for advanced routing (**Additional cost**)
- Implement NGINX Ingress for cost-effective HTTP/HTTPS termination (**Additional cost**)
- Note: Additional ingress controllers incur extra costs beyond basic AKS Load Balancer

**Cost Impact Analysis**:
- Basic AKS Load Balancer: Included in AKS pricing
- Application Gateway: ~$18-25/month base cost + data processing fees
- NGINX Ingress: Compute costs for ingress controller pods only

### Advanced Security Implementation

#### Container Security
- Use official base images with security updates
- Implement non-root user execution
- Regularly scan images for vulnerabilities
- Minimize image size and attack surface

#### Kubernetes Security
- Enable Pod Security Standards
- Implement network policies for traffic control
- Use service accounts with minimal required permissions
- Regular security updates for cluster components

#### Azure Security
- Implement Azure Policy for compliance
- Use Azure Key Vault for sensitive data management
- Enable Azure Defender for container security
- Regular review of access permissions and roles

### Production Security Checklist

#### Pre-Production Security Audit
**Container Registry Security**:
- [x] ACR admin access disabled (admin_enabled = false in Terraform)
- [x] Managed identity authentication implemented exclusively
- [ ] Enable vulnerability scanning for container images
- [ ] Configure retention policies for cost optimization

**Kubernetes Secrets Management**:
- [ ] Migrate from YAML secrets to Azure Key Vault
- [ ] Implement CSI Secret Store Driver for secure mounting
- [ ] Enable automatic secret rotation capabilities
- [ ] Remove hardcoded secrets from repository files

**Network Security**:
- [ ] Implement Kubernetes network policies for pod isolation
- [ ] Configure Azure Firewall for production environments
- [ ] Enable Azure DDoS Protection for public endpoints
- [ ] Restrict ingress access to specific IP ranges

**Monitoring and Compliance**:
- [ ] Enable Azure Defender for Kubernetes threat detection
- [ ] Configure Azure Policy for organizational compliance
- [ ] Implement comprehensive audit logging
- [ ] Set up security alerting and incident response

### Terraform State Management and Cleanup Considerations

#### Infrastructure Cleanup Best Practices
**Standard Cleanup**:
```bash
# Standard terraform destroy
terraform destroy -var-file="terraform.tfvars"
```

**Manual Resource Verification**:
```bash
# Verify complete resource removal
az resource list --resource-group <resource-group-name>

# Check for orphaned Network Security Groups
az network nsg list --resource-group <resource-group-name>

# Verify ACR deletion
az acr list --resource-group <resource-group-name>
```

**Potential Cleanup Issues**:
- Network Security Groups may persist after cluster deletion
- Container Registry might retain images affecting costs
- Azure Load Balancer resources could remain orphaned

**Complete Cleanup Script**:
```bash
# Get resource group name from terraform output
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Standard terraform destroy
terraform destroy -var-file="terraform.tfvars" -auto-approve

# Manual cleanup of potential orphaned resources
az network nsg delete --resource-group $RESOURCE_GROUP --name <nsg-name>
az network public-ip delete --resource-group $RESOURCE_GROUP --name <public-ip-name>

# Final verification
az resource list --resource-group $RESOURCE_GROUP --output table
```

#### Remote State Management
**Current Setup**: Local state files
**Production Recommendation**: Configure remote state backend
```hcl
# Add to terraform/main.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstatestg"
    container_name       = "tfstate"
    key                  = "weather-api.terraform.tfstate"
  }
}
```

### Future Enhancement Roadmap

#### DNS and HTTPS Implementation
**Ingress Controller Setup**:
```yaml
# ingress.yaml - for future implementation
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: weather-api-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.yourweather.com
    secretName: weather-api-tls
  rules:
  - host: api.yourweather.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: weather-api-service
            port:
              number: 80
```

#### Advanced Monitoring Setup
**Azure Monitor Configuration**:
```bash
# Enable Container Insights
az aks enable-addons --resource-group <resource-group> \
  --name <cluster-name> \
  --addons monitoring
```

**Log Analytics Workspace Integration**:
```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group <resource-group> \
  --workspace-name weather-api-logs
```

#### CI/CD Pipeline Enhancements
**Security Scanning Addition**:
```yaml
# Add to .github/workflows/ci-cd.yml
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: '${{ env.ACR_LOGIN_SERVER }}/weather-api:${{ github.sha }}'
        format: 'sarif'
        output: 'trivy-results.sarif'
```

## Cleanup and Resource Management

### Application Cleanup
```bash
# Remove Kubernetes resources
kubectl delete -f k8s/

# Verify resource deletion
kubectl get all -l app=weather-api
```

### Infrastructure Cleanup
```bash
# Navigate to terraform directory
cd terraform

# Preview resources to be destroyed
terraform plan -destroy -var-file="terraform.tfvars"

# Destroy infrastructure
terraform destroy -var-file="terraform.tfvars"

# Verify resource removal in Azure portal
```

### Cost Management
- Implement Azure budgets and alerts
- Regular review of resource utilization
- Consider reserved instances for production workloads
- Use Azure Cost Management for detailed cost analysis

## API Documentation

### Endpoint Specifications

#### Health Check Endpoint
- **URL**: `/health`
- **Method**: GET
- **Purpose**: Application health verification for monitoring systems
- **Response Format**:
```json
{
  "status": "healthy",
  "timestamp": "2025-08-07T10:30:00"
}
```

#### Weather Query by City Path Parameter
- **URL**: `/weather/<city>`
- **Method**: GET
- **Parameters**: city (string) - City name in URL path
- **Response Format**:
```json
{
  "city": "London",
  "country": "GB",
  "temperature": 15.3,
  "description": "light rain",
  "humidity": 82,
  "timestamp": "2025-08-07T10:30:00"
}
```

#### Weather Query by Query Parameter
- **URL**: `/weather?city=<city>`
- **Method**: GET
- **Parameters**: city (string) - City name as query parameter
- **Default**: Tel Aviv (if no city parameter provided)

### Error Handling
- **404 Not Found**: City not found in weather service
- **500 Internal Server Error**: API key issues or external service failures
- **Error Response Format**:
```json
{
  "error": "City not found"
}
```

## Contributing Guidelines

### Development Workflow
1. Fork repository and create feature branch
2. Implement changes with appropriate testing
3. Ensure all tests pass and code meets linting standards
4. Submit pull request with detailed description
5. Address review feedback and maintain code quality

### Code Quality Standards
- Follow PEP 8 style guidelines for Python code
- Maintain test coverage above 80%
- Document all functions and classes
- Use meaningful commit messages
- Implement proper error handling

### Testing Requirements
- Unit tests for all application functions
- Integration tests for API endpoints
- Infrastructure tests for Terraform configurations
- Performance tests for load scenarios
