# Terraform Infrastructure for Weather API

## תיאור כללי

תיקייה זו מכילה את כל קבצי ה-Terraform הדרושים לבניית התשתית עבור Weather API ב-Azure. התשתית כוללת AKS cluster, Azure Container Registry, ורכיבי אבטחה וניטור.

## מבנה הקבצים

```
terraform/
├── main.tf                    # הגדרות התשתית הראשיות ⭐
├── variables.tf               # משתנים להתאמה אישית
├── outputs.tf                 # נתונים שיוחזרו לאחר הרצה
├── versions.tf                # דרישות גרסאות Terraform וספקים
├── terraform.tfvars           # ערכי המשתנים שלך (יש ליצור)
├── terraform.tfvars.example   # דוגמה לקובץ המשתנים
├── README.md                  # התיעוד הראשי (הקובץ הזה)
├── QUICK_START.md            # מדריך התחלה מהירה ⚡
└── CUSTOMIZATION_GUIDE.md    # מדריך התאמות מתקדם 🔧
```

## 📚 איך להתחיל

### 🚀 התחלה מהירה (5 דקות)
קרא את **[QUICK_START.md](./QUICK_START.md)** - מדריך צעד אחר צעד

### 🔧 התאמות מתקדמות
קרא את **[CUSTOMIZATION_GUIDE.md](./CUSTOMIZATION_GUIDE.md)** - שינוי עלויות, ביצועים ואבטחה

## מה נבנה כאן?

### 🏗️ רכיבי התשתית

#### 1. Resource Group
- **שם**: `<random-prefix>-weather-api-rg`
- **מטרה**: מכיל את כל המשאבים של הפרויקט
- **מיקום**: ניתן לשינוי ב-terraform.tfvars

#### 2. AKS Cluster (Kubernetes)
- **שם**: `<random-prefix>-weather-aks`
- **גודל VM**: Standard_B2s (2 CPU, 4GB RAM)
- **Auto-scaling**: 1-3 nodes
- **רשת**: Kubenet (חסכונית)
- **SKU**: Free tier

#### 3. Azure Container Registry (ACR)
- **שם**: `<random-prefix>weatheracr`
- **SKU**: Basic tier
- **אבטחה**: Managed Identity בלבד (ללא admin access)

#### 4. Role Assignment
- מאפשר ל-AKS לשלוף images מה-ACR באופן בטוח

## פרמטרים שאפשר לשנות

### 📍 מיקום גיאוגרפי
```hcl
# בקובץ terraform.tfvars
location = "West Europe"  # אפשר לשנות ל:
# "East US"
# "West Europe" 
# "Southeast Asia"
# "Australia East"
```

### 🏷️ תגיות למעקב עלויות
```hcl
# בקובץ terraform.tfvars
tags = {
  Environment = "Development"    # או "Production"
  Project     = "WeatherAPI"     # שם הפרויקט שלך
  Owner       = "YourName"       # השם שלך
  Department  = "Engineering"    # המחלקה שלך
  CostCenter  = "R&D"           # מרכז עלות
}
```

### ⚙️ הגדרות מתקדמות (main.tf)

#### גודל VM של AKS
```hcl
# בקובץ main.tf - שורה ~65
default_node_pool {
  vm_size    = "Standard_B2s"    # אפשר לשנות ל:
  # "Standard_B1s"   # חסכוני יותר (1 CPU, 1GB)
  # "Standard_B4ms"  # חזק יותר (4 CPU, 16GB)
  # "Standard_D2s_v3" # לפרודקשן (2 CPU, 8GB)
}
```

#### כמות nodes
```hcl
# בקובץ main.tf
default_node_pool {
  min_count = 1    # מינימום nodes
  max_count = 3    # מקסימום nodes
  # אפשר לשנות לפי הצורך שלך
}
```

#### SKU של AKS
```hcl
# בקובץ main.tf
resource "azurerm_kubernetes_cluster" "main" {
  sku_tier = "Free"    # או "Standard" לפרודקשן
}
```

## איך להשתמש

### שלב 1: הכנת קובץ המשתנים
```bash
# צור את הקובץ terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# ערוך את הקובץ עם הערכים שלך
```

### שלב 2: התחלת הטרהפורם
```bash
cd terraform

# אתחול ספקים
terraform init

# בדיקת תחביר
terraform validate

# תצוגה מקדימה של השינויים
terraform plan -var-file="terraform.tfvars"
```

### שלב 3: בניית התשתית
```bash
# בניה בפועל
terraform apply -var-file="terraform.tfvars"
# הקלד "yes" לאישור
```

### שלב 4: קבלת פרטי התשתית
```bash
# שם ה-cluster
terraform output kubernetes_cluster_name

# שם Resource Group
terraform output resource_group_name

# כתובת ACR
terraform output acr_login_server
```

## מה יוצא לך מהטרהפורם?

### 💰 עלויות משוערות (חודשיות)
- **AKS Management**: חינם (Free tier)
- **VM Instances**: ~$30-50 (Standard_B2s)
- **Storage**: ~$4-6 (30GB SSD)
- **ACR**: ~$5 (Basic tier)
- **Network**: ~$5-10
- **סה"כ**: ~$45-70 לחודש

### 📊 ביצועים
- **CPU**: 2-6 cores (תלוי ב-scaling)
- **Memory**: 4-12GB RAM
- **Storage**: 30GB per node
- **Network**: 1Gbps

## התאמות אישיות נפוצות

### 🌍 שינוי מיקום לישראל
אם אתה רוצה שהשרתים יהיו קרובים יותר לישראל:
```hcl
# בקובץ terraform.tfvars
location = "West Europe"  # הכי קרוב לישראל
# או
location = "East US"      # חלופה טובה
```

### 💪 הגדלת כוח חישוב
אם אתה צופה עומס גבוה:
```hcl
# בקובץ main.tf
default_node_pool {
  vm_size    = "Standard_D2s_v3"  # חזק יותר
  min_count  = 2                   # מינימום 2 nodes
  max_count  = 5                   # עד 5 nodes
}
```

### 🔒 הגדרות אבטחה מתקדמות
```hcl
# בקובץ main.tf - אפשר להוסיף:
network_profile {
  network_plugin = "azure"    # במקום kubenet לאבטחה מתקדמת
  network_policy = "azure"    # הגבלות רשת
}
```

## פקודות שימושיות

### 🔍 בדיקת מצב נוכחי
```bash
# רשימת משאבים שנוצרו
terraform state list

# מידע מפורט על משאב ספציפי
terraform state show azurerm_kubernetes_cluster.main

# בדיקת drift (שינויים חיצוניים)
terraform plan -var-file="terraform.tfvars"
```

### 🔄 עדכון התשתית
```bash
# לאחר שינוי בקבצים
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### 🧹 מחיקת התשתית
```bash
# מחיקה מלאה (זהירות!)
terraform destroy -var-file="terraform.tfvars"
```

## קבצי קונפיגורציה נדרשים

### terraform.tfvars (יש ליצור)
```hcl
location = "West Europe"

tags = {
  Environment = "Development"
  Project     = "WeatherAPI"
  Owner       = "YourName"
  Department  = "R&D"
  Team        = "DevOps"
}
```

### .gitignore (כבר קיים)
```
# Terraform files
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfvars
```

## טרובלשוטינג נפוץ

### ❌ שגיאת הרשאות
```bash
# ודא שאתה מחובר ל-Azure
az login
az account show
```

### ❌ שם ACR כבר תפוס
הטרהפורם ייצור שם אקראי, אבל אם יש בעיה:
```hcl
# בקובץ main.tf - שנה את השם
name = "yourname${replace(random_pet.prefix.id, "-", "")}weatheracr"
```

### ❌ בעיות quota
```bash
# בדוק מגבלות המנוי שלך
az vm list-usage --location "West Europe" -o table
```

## הרחבות עתידיות אפשריות

### 🔐 Azure Key Vault
```hcl
resource "azurerm_key_vault" "main" {
  name                = "${random_pet.prefix.id}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name           = "standard"
  tenant_id          = data.azurerm_client_config.current.tenant_id
}
```

### 📊 Log Analytics
```hcl
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${random_pet.prefix.id}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                = "PerGB2018"
  retention_in_days  = 30
}
```

### 🌐 Application Gateway
```hcl
resource "azurerm_application_gateway" "main" {
  name                = "${random_pet.prefix.id}-appgw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # ... additional configuration
}
```

## מבנה קוד מומלץ

```
terraform/
├── main.tf              # משאבים ראשיים
├── variables.tf          # הגדרות משתנים
├── outputs.tf           # מוצאים
├── versions.tf          # דרישות ספקים
├── terraform.tfvars     # ערכים אישיים
├── modules/             # מודולים מקומיים
│   ├── aks/
│   ├── acr/
│   └── monitoring/
└── environments/        # סביבות שונות
    ├── dev/
    ├── staging/
    └── prod/
```

## סיכום

הטרהפורם הזה נותן לך:
- ✅ תשתית מוכנה לפרודקשן
- ✅ עלויות אופטימליות  
- ✅ אבטחה מתקדמת
- ✅ גמישות להתאמות
- ✅ ניהול אוטומטי

**הכל מוכן לשימוש, רק תצור את terraform.tfvars ותתחיל!**
