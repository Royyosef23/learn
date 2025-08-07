# מדריך הפעלה מלא - Weather API Project

## סיכום הפרויקט
פרויקט זה הוא Weather API שרץ על Azure Kubernetes Service (AKS) עם CI/CD pipeline מלא. הפרויקט כולל:
- Flask API עם OpenWeatherMap integration
- Docker containerization
- Terraform לניהול infrastructure
- GitHub Actions לאוטומציה
- Kubernetes deployment על Azure

## שגיאה נפוצה - GitHub Actions נכשל

**אם אתה רואה שגיאה כמו:**
```
Error: Input required and not supplied: username
```

**זה אומר שעדיין לא הגדרת את ה-secrets ב-GitHub!**

### דרך מהירה לעצור את הכשלונות:
1. עבור ל-GitHub repository → Actions
2. ב-workflow שנכשל, לחץ "Cancel workflow"
3. **ודא שאתה משלים את כל השלבים לפני push נוסף**

### סדר נכון (חשוב!):
1. **קודם**: הרץ `terraform apply` (שלב A)
2. **אחר כך**: הגדר את כל ה-secrets (שלב C) 
3. **רק אז**: תעשה push שיפעיל את ה-workflow

**אל תעשה push לפני שסיימת את ההגדרות!**

### 1. Azure Service Principal - חובה ראשון
```bash
# התחבר ל-Azure
az login

# בדוק מה ה-subscription ID שלך
az account show --query id --output tsv

# צור service principal (החלף SUBSCRIPTION_ID בערך שקיבלת למעלה)
az ad sp create-for-rbac --name "github-actions-weather-api" \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID \
  --sdk-auth
```

**שמור את הפלט!** זה ייראה כך:
```json
{
  "clientId": "12345678-1234-1234-1234-123456789abc",
  "clientSecret": "your-client-secret-here", 
  "subscriptionId": "87654321-4321-4321-4321-cba987654321",
  "tenantId": "11111111-2222-3333-4444-555555555555"
}
```

### 2. OpenWeatherMap API Key - חובה שני
1. הירשם ב: https://openweathermap.org/api
2. קבל API key (חינם)
3. קודד אותו ל-base64:
```bash
echo -n "your-api-key-here" | base64
```
4. שמור את הערך המקודד

### 3. Terraform Variables File - יצירה ידנית
צור קובץ `terraform/terraform.tfvars`:
```hcl
location = "West Europe"
tags = {
  Environment = "Development" 
  Project     = "WeatherAPI"
  Owner       = "YourName"
}
```

### 4. עדכון Secret ב-Kubernetes
ערוך את `k8s/secret.yaml` והחלף את `your-base64-encoded-api-key` בערך שקיבלת בשלב 2.

## תהליך ההפעלה המלא - צעד אחר צעד

### שלב A: הכנת Infrastructure
```bash
# נווט לתיקיית terraform
cd terraform

# אתחל terraform
terraform init

# בדוק מה יקרה
terraform plan -var-file="terraform.tfvars"

# יצור את ה-infrastructure
terraform apply -var-file="terraform.tfvars"
```

### שלב B: איסוף מידע מה-Infrastructure
לאחר שטרפורם הסתיים בהצלחה, הרץ:
```bash
# קבל את שמות המשאבים
terraform output aks_cluster_name
terraform output resource_group_name  
terraform output acr_login_server

# קבל פרטי גישה ל-ACR
az acr credential show --name $(terraform output -raw acr_name)
```

### שלב C: הגדרת GitHub Secrets
עבור ל-GitHub repository → Settings → Secrets and variables → Actions

הוסף את הסודות הבאים (בדיוק עם השמות האלה):

**מה-Service Principal שיצרת:**
- `ARM_CLIENT_ID` = clientId
- `ARM_CLIENT_SECRET` = clientSecret  
- `ARM_SUBSCRIPTION_ID` = subscriptionId
- `ARM_TENANT_ID` = tenantId
- `AZURE_CREDENTIALS` = כל ה-JSON המלא

**מ-Terraform outputs:**
- `AKS_CLUSTER_NAME` = שם הקלאסטר
- `AKS_RESOURCE_GROUP` = שם ה-resource group
- `ACR_LOGIN_SERVER` = כתובת ה-ACR

**מ-ACR credentials:**
- `ACR_USERNAME` = username
- `ACR_PASSWORD` = password

### שלב D: הפעלת CI/CD
```bash
# עדכן את השינויים
git add .
git commit -m "Configure secrets and deploy"
git push origin dev  # יפעיל deployment לסביבת dev
```

## איך הפרויקט עובד

### Branch Strategy
- **dev branch**: deployment אוטומטי לסביבת פיתוח (namespace: dev)
- **main branch**: deployment אוטומטי לסביבת production (namespace: default)
- **feature branches**: רק testing, ללא deployment

### GitHub Actions Workflows
1. **CI/CD Pipeline** (אוטומטי על push):
   - Test → Build → Deploy
   - dev branch = dev environment
   - main branch = production environment

2. **Infrastructure Workflow** (ידני):
   - Actions tab → Infrastructure Deployment
   - plan/apply/destroy options

### בדיקת התוצאה
```bash
# התחבר לקלאסטר
az aks get-credentials --resource-group <rg-name> --name <cluster-name>

# בדוק את ה-pods
kubectl get pods -l app=weather-api -n dev  # for dev environment
kubectl get pods -l app=weather-api         # for production

# בדוק את השירות  
kubectl get service weather-api-service -n dev

# בדיקה מקומית
kubectl port-forward service/weather-api-service 8080:80 -n dev
curl "http://localhost:8080/weather/London"
curl "http://localhost:8080/health"
```

## נקודות חשובות לזכור

### עלויות
- הפרויקט מתוכנן להיות זול (~$65-70/חודש)
- AKS Free tier (ללא עלות ניהול)
- Standard_B2s VMs (burstable, חסכוני)
- Auto-scaling: 1-3 nodes

### אבטחה
- Service Principal עם הרשאות מינימליות
- Secrets מנוהלים ב-GitHub ו-Kubernetes
- Non-root containers
- RBAC enabled

### Troubleshooting נפוצים
```bash
# אם pods לא מתחילים
kubectl describe pod <pod-name> -n dev
kubectl logs <pod-name> -n dev

# אם יש בעיות image pull
az acr login --name <acr-name>
kubectl get secret regcred -o yaml

# בדיקת resources
kubectl top nodes
kubectl top pods -n dev
```

## מה קורה אם משהו לא עובד

### GitHub Actions נכשל
1. בדוק Actions tab ב-GitHub
2. ודא שכל ה-secrets מוגדרים נכון
3. בדוק שה-Service Principal פעיל

### Infrastructure Issues  
```bash
# ניקוי infrastructure
terraform destroy -auto-approve

# בדיקת משאבים ב-Azure
az resource list --resource-group <rg-name>
```

### API לא עובד
1. ודא ש-OpenWeatherMap API key תקין
2. בדוק שה-secret.yaml מעודכן נכון
3. בדוק logs של ה-pods

## סיכום הדברים שאתה חייב לעשות
1. צור Azure Service Principal
2. קבל OpenWeatherMap API key  
3. צור terraform.tfvars
4. עדכן k8s/secret.yaml
5. הרץ terraform apply
6. הגדר GitHub secrets
7. push לגיט כדי להפעיל deployment

זה הכל! לאחר השלבים האלה הפרויקט יעבוד אוטומטית.
