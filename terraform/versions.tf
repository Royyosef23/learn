# Terraform Provider Version Constraints
# קובץ זה מגדיר את הגרסאות הנדרשות של Terraform והספקים

terraform {
  # גרסת Terraform מינימלית נדרשת
  required_version = ">= 1.0"

  # ספקי השירות הנדרשים
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # גרסה 3.x (יציבה ומומלצת)
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"  # ליצירת שמות אקראיים
    }
  }
}

# הגדרות ספק Azure
provider "azurerm" {
  features {
    # הגדרות מתקדמות לניהול משאבים
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# מידע על הקונטקסט הנוכחי של Azure
data "azurerm_client_config" "current" {}
