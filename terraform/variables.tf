variable "project_name" {
  description = "Short project identifier used in resource naming"
  type        = string
  default     = "Challange"

  validation {
    condition     = length(var.project_name) <= 16
    error_message = "Project name must be 16 characters or less for storage account naming."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag for resource identification"
  type        = string
  default     = "Matheus"
}

variable "dotnet_version" {
  description = ".NET runtime version for the Function App"
  type        = string
  default     = "8.0"
}
