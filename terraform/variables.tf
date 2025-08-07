variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"  # Usually cheaper than other regions
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "WeatherAPI"
    ManagedBy   = "Terraform"
    CostCenter  = "Development"
  }
}
