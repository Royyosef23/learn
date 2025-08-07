# GitHub Actions Setup Guide

## 🔐 Required GitHub Secrets

### Azure Authentication
יש להוסיף את הסודות הבאים ב-GitHub repository settings:

1. **Azure Service Principal** (עבור Terraform):
   ```
   ARM_CLIENT_ID: <service-principal-app-id>
   ARM_CLIENT_SECRET: <service-principal-password>
   ARM_SUBSCRIPTION_ID: <azure-subscription-id>
   ARM_TENANT_ID: <azure-tenant-id>
   ```

2. **Azure Container Registry**:
   ```
   ACR_LOGIN_SERVER: <acr-name>.azurecr.io
   ACR_USERNAME: <acr-admin-username>
   ACR_PASSWORD: <acr-admin-password>
   ```

3. **AKS Cluster Info**:
   ```
   AKS_CLUSTER_NAME: <aks-cluster-name>
   AKS_RESOURCE_GROUP: <resource-group-name>
   AZURE_CREDENTIALS: <service-principal-json>
   ```

## 🏗️ Service Principal יצירת

### שלב 1: יצירת Service Principal
```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

### שלב 2: העתקת הפלט
השמר את הפלט JSON - זה יהיה ה-`AZURE_CREDENTIALS`:
```json
{
  "clientId": "xxx",
  "clientSecret": "xxx",
  "subscriptionId": "xxx",
  "tenantId": "xxx"
}
```

## 🚀 Workflow Overview

### 1. **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
- **Trigger**: Push to `main` או `dev`
- **Test**: pytest, linting
- **Build**: Docker image
- **Deploy**: 
  - `main` → Production AKS
  - `dev` → Development environment

### 2. **Infrastructure** (`.github/workflows/infrastructure.yml`)
- **Manual trigger** (workflow_dispatch)
- **Actions**: plan, apply, destroy
- **Environments**: dev, prod

## 📋 Git Workflow מומלץ

### Branch Strategy:
```
main (production)
├── dev (development)
├── feature/weather-improvements
└── hotfix/api-key-fix
```

### Development Process:
1. **Feature development**:
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/new-feature
   # ... עבודה על הפיצ'ר
   git push origin feature/new-feature
   # יצירת PR ל-dev
   ```

2. **Development testing**:
   ```bash
   git checkout dev
   git merge feature/new-feature
   git push origin dev  # Auto-deploy to dev environment
   ```

3. **Production release**:
   ```bash
   git checkout main
   git merge dev
   git push origin main  # Auto-deploy to production
   ```

## 🎯 Environments Setup

### GitHub Repository Settings:
1. **Settings** → **Environments**
2. יצירת environments:
   - `development`
   - `production`

3. **Protection rules** עבור production:
   - Required reviewers
   - Wait timer
   - Deployment branches: `main` only

## 🔧 Local Development Commands

### בדיקת קוד:
```bash
# Install dependencies
pip install -r requirements.txt
pip install pytest pytest-cov flake8

# Run tests
pytest tests/ -v

# Lint check
flake8 app.py

# Local Docker build
docker build -t weather-api .
docker run -p 5000:5000 -e WEATHER_API_KEY=your-key weather-api
```

### Terraform local:
```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## 📊 Monitoring & Debugging

### GitHub Actions:
- **Actions tab**: צפייה בריצות
- **Workflow logs**: debug מפורט
- **Environment logs**: deployment status

### AKS Troubleshooting:
```bash
# Connect to cluster
az aks get-credentials --resource-group <rg> --name <cluster>

# Check deployment
kubectl get pods -l app=weather-api
kubectl logs -l app=weather-api --tail=50
kubectl describe deployment weather-api

# Check service
kubectl get service weather-api-service
kubectl describe service weather-api-service
```

## 🚨 Emergency Procedures

### Rollback Production:
```bash
# Via kubectl
kubectl rollout undo deployment/weather-api

# Via GitHub Actions
# Re-run previous successful deployment
```

### Infrastructure Issues:
```bash
# Manual terraform destroy
cd terraform
terraform destroy -auto-approve

# Check Azure resources
az resource list --resource-group <rg-name>
```

## 📈 Cost Monitoring

### Azure Cost Management:
- Budget alerts
- Daily cost tracking
- Resource utilization

### Optimization Actions:
- Scale down dev environment after hours
- Use spot instances for testing
- Monitor ACR storage usage
