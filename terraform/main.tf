# ========================================
# Weather API Infrastructure on Azure
# ========================================
# קובץ זה מגדיר את כל התשתית הנדרשת עבור Weather API:
# - AKS Cluster (Kubernetes)
# - Azure Container Registry (ACR)
# - Resource Group
# - Role Assignments for Security

# ========================================
# Resource Naming
# ========================================
# יוצר שם אקראי ייחודי למשאבים כדי למנוע התנגשויות שמות
resource "random_pet" "prefix" {
  length = 2  # שני מילים (כגון: "clever-dog")
}

# ========================================
# Resource Group - מכיל את כל המשאבים
# ========================================
resource "azurerm_resource_group" "main" {
  name     = "${random_pet.prefix.id}-weather-api-rg"  # שם: clever-dog-weather-api-rg
  location = var.location  # מיקום מ-terraform.tfvars

  tags = var.tags  # תגיות מ-terraform.tfvars למעקב עלויות
}

# ========================================
# AKS Cluster - הלב של התשתית
# ========================================
# אפשרויות להתאמה:
# - vm_size: Standard_B1s (חסכוני), Standard_D2s_v3 (לפרודקשן)
# - sku_tier: "Free" (עד 10 nodes), "Standard" (לפרודקשן)
# - min_count/max_count: כמות nodes (משפיע על עלויות!)

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${random_pet.prefix.id}-weather-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${random_pet.prefix.id}-weather"
  
  # SKU: "Free" = חינם עד 10 nodes, "Standard" = לפרודקשן
  sku_tier = "Free"
  
  # הגדרות Node Pool - כאן קובעים עלויות!
  default_node_pool {
    name                = "default"
    
    # ===== עלויות - שנה כאן! =====
    node_count          = 1              # התחל עם node אחד
    vm_size             = "Standard_B2s" # 2 CPU, 4GB RAM (~$30/חודש)
    # אפשרויות אחרות:
    # "Standard_B1s"   # 1 CPU, 1GB RAM (~$15/חודש) - חסכוני
    # "Standard_D2s_v3" # 2 CPU, 8GB RAM (~$70/חודש) - לפרודקשן
    
    # הגדרות דיסק
    os_disk_size_gb     = 30    # 30GB לכל node (מינימום)
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    
    # ===== Auto-scaling - חסכון אוטומטי! =====
    enable_auto_scaling = true
    min_count          = 1   # מינימום nodes (לא פחות)
    max_count          = 3   # מקסימום nodes (שנה אם צריך יותר)
    # שים לב: כל node נוסף = עלות נוספת!
    
    # ===== חיסכון נוסף - Spot Instances (ניסיוני) =====
    # spot_max_price = -1  # הסר # להפעלה - חוסך 80% אבל לא יציב
  }

  # ===== אבטחה - Managed Identity =====
  identity {
    type = "SystemAssigned"  # Azure מנהל את הCredentials אוטומטית
  }

  # ===== רשת - חסכוני ופשוט =====
  network_profile {
    network_plugin = "kubenet"        # חסכוני יותר מ-Azure CNI
    load_balancer_sku = "standard"   # Load Balancer כלול
    # לפרודקשן מתקדם אפשר לשנות ל:
    # network_plugin = "azure"       # יותר תכונות אבל יותר יקר
    # network_policy = "azure"       # אבטחת רשת מתקדמת
  }

  # ===== אבטחה - RBAC =====
  role_based_access_control_enabled = true  # ניהול הרשאות מתקדם

  tags = var.tags
}

# ========================================
# Azure Container Registry (ACR)
# ========================================
# שומר את Docker Images של האפליקציה בצורה בטוחה
# אפשרויות SKU: Basic (~$5/חודש), Standard (~$20/חודש), Premium (~$50/חודש)

resource "azurerm_container_registry" "main" {
  name                = "${replace(random_pet.prefix.id, "-", "")}weatheracr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  # ===== עלויות - SKU =====
  sku                 = "Basic"  # הכי זול - מספיק למפתחים
  # "Standard" = יותר bandwidth לפרודקשן
  # "Premium" = גיאו-replication ותכונות מתקדמות
  
  # ===== אבטחה - ללא Admin Access! =====
  admin_enabled       = false   # בטוח יותר - משתמש ב-Managed Identity בלבד

  tags = var.tags
}

# ========================================
# Security Role Assignment
# ========================================
# מאפשר ל-AKS לשלוף Docker Images מה-ACR בצורה בטוחה
# ללא צורך בusername/password!

resource "azurerm_role_assignment" "aks_acr" {
  # מי מקבל הרשאה: ה-Managed Identity של AKS
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  
  # איזה הרשאה: רק לשלוף images (לא לדחוף)
  role_definition_name = "AcrPull"
  
  # על איזה משאב: על ה-ACR שלנו
  scope               = azurerm_container_registry.main.id
  
  # דלג על בדיקות AAD (מקורה ב-Terraform limitation)
  skip_service_principal_aad_check = true
}

# ========================================
# התשתית הושלמה בהצלחה!
# ========================================
# המשאבים שנוצרו:
# 1. Resource Group - מכיל הכל
# 2. AKS Cluster - רץ על 1-3 nodes
# 3. ACR - מאחסן Docker images
# 4. Role Assignment - מחבר אותם בבטחה
#
# העלות המשוערת: $45-70 לחודש
# זמן בנייה: 5-10 דקות
# ========================================
