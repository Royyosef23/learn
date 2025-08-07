# ========================================
# Terraform Variables - הגדרות להתאמה אישית
# ========================================
# קובץ זה מגדיר את כל הפרמטרים שאפשר לשנות
# הערכים בפועל נקבעים בקובץ terraform.tfvars

# ========================================
# מיקום גיאוגרפי
# ========================================
variable "location" {
  description = "המיקום הגיאוגרפי של המשאבים ב-Azure"
  type        = string
  default     = "West Europe"  # ברירת מחדל: אמסטרדם (הכי קרוב לישראל)
  
  # אפשרויות מומלצות:
  # "West Europe"      - אמסטרדם (הכי קרוב לישראל)
  # "East US"          - וירג'יניה (זול ומהיר)
  # "North Europe"     - אירלנד (קרוב)
  # "Southeast Asia"   - סינגפור (טוב לאסיה)
  
  validation {
    condition = contains([
      "West Europe", "East US", "North Europe", "Southeast Asia",
      "Central US", "West US 2", "UK South", "France Central"
    ], var.location)
    error_message = "מיקום לא נתמך. בחר מיקום מהרשימה המומלצת."
  }
}

# ========================================
# תגיות למעקב עלויות וניהול
# ========================================
variable "tags" {
  description = "תגיות שיוחלו על כל המשאבים (חשוב למעקב עלויות!)"
  type        = map(string)
  
  # ערכי ברירת מחדל - ערוך ב-terraform.tfvars
  default = {
    Environment = "Development"
    Project     = "WeatherAPI"
    ManagedBy   = "Terraform"
    CostCenter  = "Development"
  }
  
  validation {
    condition     = contains(keys(var.tags), "Environment")
    error_message = "התג 'Environment' חובה לכל משאב."
  }
  
  validation {
    condition     = contains(keys(var.tags), "Project")
    error_message = "התג 'Project' חובה למעקב עלויות."
  }
}

# ========================================
# משתנים אופציונליים (לעתיד)
# ========================================

# האם להפעיל cluster פרטי (ללא access מהאינטרנט)
variable "enable_private_cluster" {
  description = "האם ליצור AKS cluster פרטי (מומלץ לפרודקשן)"
  type        = bool
  default     = false  # false = public cluster (חינם), true = private (עלות נוספת)
}

# טווח IP מורשה לגישה (אופציונלי)
variable "authorized_ip_ranges" {
  description = "טווחי IP מורשים לגישה ל-AKS API server"
  type        = list(string)
  default     = []  # רשימה ריקה = גישה מכל מקום
  
  # דוגמה לשימוש:
  # authorized_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
}

# קידומת מותאמת אישית לשמות משאבים
variable "resource_prefix" {
  description = "קידומת אופציונלית לשמות משאבים (במקום random name)"
  type        = string
  default     = ""  # ריק = השתמש בשם אקראי
  
  validation {
    condition     = var.resource_prefix == "" || can(regex("^[a-z0-9-]+$", var.resource_prefix))
    error_message = "הקידומת יכולה להכיל רק אותיות קטנות, מספרים ומקפים."
  }
}
