# Terraform Customization Guide - מדריך התאמות

## שינויים נפוצים שתרצה לעשות

### 🌍 שינוי מיקום לחסכון/ביצועים

#### הכי קרוב לישראל (מומלץ)
```hcl
# בקובץ terraform.tfvars
location = "West Europe"  # אמסטרדם - 3,300 ק"מ מישראל
```

#### הכי זול (אם עלויות חשובות)
```hcl
location = "East US"      # וירג'יניה - זול יותר מאירופה
```

#### איזור אסיה (אם יש לך לקוחות באסיה)
```hcl
location = "Southeast Asia"  # סינגפור
```

### 💰 התאמת עלויות

#### חסכון מקסימלי
```hcl
# בקובץ main.tf - שנה את הפרמטרים האלה:

default_node_pool {
  vm_size    = "Standard_B1s"  # 1 CPU, 1GB RAM (~$15/חודש במקום $30)
  min_count  = 1
  max_count  = 2               # מקסימום 2 nodes במקום 3
}

# ACR - אפשר להשאיר Basic או לעבור ל-Shared
sku = "Basic"  # $5/חודש
```

#### עלויות בינוניות (מומלץ)
```hcl
default_node_pool {
  vm_size    = "Standard_B2s"  # 2 CPU, 4GB RAM (~$30/חודש) - ברירת מחדל
  min_count  = 1
  max_count  = 3
}
```

#### לפרודקשן (ביצועים גבוהים)
```hcl
default_node_pool {
  vm_size    = "Standard_D2s_v3"  # 2 CPU, 8GB RAM (~$70/חודש)
  min_count  = 2                   # תמיד לפחות 2 nodes
  max_count  = 5                   # עד 5 nodes
}

sku_tier = "Standard"  # $10/חודש נוסף - תכונות פרודקשן
```

### 🚀 שיפור ביצועים

#### רשת מתקדמת
```hcl
# בקובץ main.tf - החלף את network_profile:
network_profile {
  network_plugin = "azure"       # במקום kubenet - יותר תכונות
  network_policy = "azure"       # הגבלות רשת מתקדמות
  dns_service_ip = "10.2.0.10"   # DNS פנימי
  service_cidr   = "10.2.0.0/24" # טווח IP לשירותים
}
```

#### דיסק מהיר יותר
```hcl
default_node_pool {
  os_disk_type    = "Ephemeral"  # דיסק מהיר יותר (אבל נמחק בעדכונים)
  os_disk_size_gb = 50           # יותר מקום
}
```

### 🔒 שיפור אבטחה

#### Cluster פרטי
```hcl
# בקובץ terraform.tfvars
enable_private_cluster = true

# בקובץ main.tf הוסף:
private_cluster_enabled = var.enable_private_cluster
```

#### הגבלת גישה לIP ספציפי
```hcl
# בקובץ terraform.tfvars
authorized_ip_ranges = ["YOUR_IP_ADDRESS/32"]

# בקובץ main.tf הוסף:
api_server_access_profile {
  authorized_ip_ranges = var.authorized_ip_ranges
}
```

### 🏷️ תגיות מותאמות אישית

#### לעסק/ארגון
```hcl
# בקובץ terraform.tfvars
tags = {
  Environment   = "Production"
  Project       = "WeatherAPI"
  Owner         = "John Doe"
  Email         = "john@company.com"
  Department    = "Engineering"
  Team          = "Platform"
  CostCenter    = "Engineering-001"
  Budget        = "Q1-2025"
  Application   = "weather-service"
  BusinessUnit  = "Digital Products"
  Compliance    = "SOC2"
}
```

#### לפרויקט אישי
```hcl
tags = {
  Environment = "Personal"
  Project     = "WeatherApp"
  Owner       = "Your Name"
  Purpose     = "Learning"
  Budget      = "hobby"
}
```

### 📦 ACR התאמות

#### לפיתוח (הכי זול)
```hcl
resource "azurerm_container_registry" "main" {
  sku = "Basic"  # $5/חודש, 10GB storage
  
  # אפשר להוסיף retention policy
  retention_policy {
    days    = 7
    enabled = true
  }
}
```

#### לפרודקשן
```hcl
resource "azurerm_container_registry" "main" {
  sku = "Premium"  # $50/חודש, גיאו-replication
  
  georeplications {
    location = "East US"
    tags     = var.tags
  }
}
```

### 🔧 Spot Instances לחסכון קיצוני

```hcl
# בקובץ main.tf - הוסף לdefault_node_pool:
spot_max_price = -1  # שימוש במחיר השוק
priority       = "Spot"
eviction_policy = "Delete"

# ⚠️ זהירות: Spot instances יכולים להיות terminated בכל רגע!
# מתאים רק לפיתוח/בדיקות, לא לפרודקשן
```

### 🔄 יצירת environments נפרדים

#### structure מומלץ:
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       └── terraform.tfvars
└── modules/
    └── aks-cluster/
```

#### dev environment
```hcl
# environments/dev/terraform.tfvars
location = "West Europe"
tags = {
  Environment = "Development"
  # ... שאר התגיות
}

# בmain.tf:
vm_size = "Standard_B1s"
min_count = 1
max_count = 2
```

#### prod environment
```hcl
# environments/prod/terraform.tfvars
location = "West Europe"
tags = {
  Environment = "Production"
  # ... שאר התגיות
}

# בmain.tf:
vm_size = "Standard_D2s_v3"
min_count = 2
max_count = 5
sku_tier = "Standard"
```

### 🛠️ תוספות שימושיות

#### Log Analytics
```hcl
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${random_pet.prefix.id}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = var.tags
}

# הוסף ל-AKS:
oms_agent {
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}
```

#### Azure Key Vault
```hcl
resource "azurerm_key_vault" "main" {
  name                = "${random_pet.prefix.id}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name = "standard"
  
  tags = var.tags
}
```

## פקודות שימושיות לאחר שינויים

### תצוגה מקדימה
```bash
terraform plan -var-file="terraform.tfvars"
```

### יישום שינויים
```bash
terraform apply -var-file="terraform.tfvars"
```

### בדיקת מצב נוכחי
```bash
terraform state list
terraform show
```

### חזרה לגרסה קודמת
```bash
git checkout HEAD~1 -- main.tf
terraform plan -var-file="terraform.tfvars"
```

## טיפים חשובים

1. **תמיד הרץ plan לפני apply**
2. **בדוק עלויות ב-Azure Cost Management אחרי שינויים**
3. **גבה את קובץ .tfstate לפני שינויים גדולים**
4. **השתמש בגיט לmanage השינויים**
5. **בדוק שה-AKS cluster מתפקד אחרי שינויים**

זוכר: כל שינוי ב-VM size או כמות nodes משפיע על העלויות!
