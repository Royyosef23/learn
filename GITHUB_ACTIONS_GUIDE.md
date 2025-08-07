# GitHub Actions Setup Guide

## Repository Secrets Configuration

**IMPORTANT**: יש להגדיר את הסודות הבאים ב-GitHub repository לפני שניתן להשתמש ב-CI/CD pipeline.

### Step 1: Navigate to Repository Settings
1. עבור לעמוד הראשי של ה-repository ב-GitHub
2. לחץ על "Settings" בתפריט העליון
3. בתפריט הצדדי השמאלי, לחץ על "Secrets and variables" ← "Actions"
4. לחץ על "New repository secret"

### Step 2: Azure Service Principal Creation

**Prerequisites**: Azure CLI מותקן ומחובר לחשבון Azure שלך

```bash
# Login to Azure
az login

# Get subscription ID
az account show --query id --output tsv

# Create service principal (החלף את SUBSCRIPTION_ID בערך האמיתי)
az ad sp create-for-rbac --name "github-actions-weather-api" \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID \
  --sdk-auth
```

**Output Example**:
```json
{
  "clientId": "12345678-1234-1234-1234-123456789abc",
  "clientSecret": "your-client-secret-here",
  "subscriptionId": "87654321-4321-4321-4321-cba987654321",
  "tenantId": "11111111-2222-3333-4444-555555555555"
}
```

### Step 3: Required Repository Secrets

Add each of the following secrets to your GitHub repository:

#### Azure Authentication Secrets
1. **ARM_CLIENT_ID**
   - Value: `clientId` from service principal output
   - Example: `12345678-1234-1234-1234-123456789abc`

2. **ARM_CLIENT_SECRET**
   - Value: `clientSecret` from service principal output
   - Example: `your-client-secret-here`

3. **ARM_SUBSCRIPTION_ID**
   - Value: `subscriptionId` from service principal output
   - Example: `87654321-4321-4321-4321-cba987654321`

4. **ARM_TENANT_ID**
   - Value: `tenantId` from service principal output
   - Example: `11111111-2222-3333-4444-555555555555`

5. **AZURE_CREDENTIALS**
   - Value: הוע JSON המלא מיצירת service principal
   - Example: `{"clientId":"12345...","clientSecret":"your-secret...","subscriptionId":"87654...","tenantId":"11111..."}`

#### Infrastructure Secrets (יהיו זמינים לאחר הרצת Terraform)
6. **AKS_CLUSTER_NAME**
   - Value: שם הקלאסטר מ-Terraform output
   - Example: `clever-dog-weather-aks`

7. **AKS_RESOURCE_GROUP**
   - Value: שם ה-resource group מ-Terraform output
   - Example: `clever-dog-ROY_API_RG`

#### Container Registry Secrets (יהיו זמינים לאחר הרצת Terraform)
8. **ACR_LOGIN_SERVER**
   - Value: כתובת ה-ACR מ-Terraform output
   - Example: `cleverdogweatheracr.azurecr.io`

9. **ACR_USERNAME**
   - Value: ACR admin username
   - Get via: `az acr credential show --name <acr-name> --query username --output tsv`

10. **ACR_PASSWORD**
    - Value: ACR admin password
    - Get via: `az acr credential show --name <acr-name> --query passwords[0].value --output tsv`

### Step 4: OpenWeatherMap API Key Configuration

1. הירשם ב-https://openweathermap.org/api
2. קבל API key חינמי
3. צור base64 encoding של המפתח:
```bash
echo -n "your-openweathermap-api-key" | base64
```
4. עדכן את `k8s/secret.yaml` עם הערך המקודד

### Step 5: Deployment Order

**Important**: יש לפעול בסדר הבא:

1. **Infrastructure Deployment** (manual via Terraform):
```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

2. **Extract Infrastructure Values**:
```bash
# Get AKS cluster name
terraform output aks_cluster_name

# Get resource group name
terraform output resource_group_name

# Get ACR login server
terraform output acr_login_server

# Get ACR credentials
az acr credential show --name $(terraform output -raw acr_name)
```

3. **Configure Repository Secrets** with the extracted values

4. **Update k8s/secret.yaml** with encoded API key

5. **Commit and Push** to trigger CI/CD pipeline

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
