# ========================================
# Terraform Outputs - המידע שתקבל לאחר הבנייה
# ========================================
# הערכים האלה יוצגו בסוף הרצת terraform apply
# תצטרך אותם עבור GitHub Secrets ו-kubectl

# ========================================
# מידע בסיסי על התשתית
# ========================================

output "resource_group_name" {
  description = "שם ה-Resource Group שנוצר"
  value       = azurerm_resource_group.main.name
}

output "kubernetes_cluster_name" {
  description = "שם ה-AKS Cluster (תצטרך לkubectl)"
  value       = azurerm_kubernetes_cluster.main.name
}

output "kubernetes_cluster_fqdn" {
  description = "כתובת מלאה של ה-AKS Cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "acr_login_server" {
  description = "כתובת ה-Container Registry (תצטרך לGitHub Secrets)"
  value       = azurerm_container_registry.main.login_server
}

# ========================================
# מידע לחיבור kubectl
# ========================================

output "kube_config_command" {
  description = "הפקודה לחיבור kubectl ל-AKS"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

# ========================================
# מידע נוסף שימושי
# ========================================

output "location" {
  description = "המיקום הגיאוגרפי של המשאבים"
  value       = azurerm_resource_group.main.location
}

output "resource_group_id" {
  description = "מזהה ייחודי של ה-Resource Group"
  value       = azurerm_resource_group.main.id
  sensitive   = false
}

output "acr_name" {
  description = "שם ה-Container Registry (ללא .azurecr.io)"
  value       = azurerm_container_registry.main.name
}

# ========================================
# הערות אבטחה חשובות
# ========================================
# Note: ACR admin credentials removed for security
# AKS uses managed identity to access ACR (configured via role assignment)
# No username/password needed - Azure handles authentication automatically!
