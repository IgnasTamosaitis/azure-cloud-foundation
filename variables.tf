variable "location" {
  description = "Azure deployment region"
  type        = string
  default     = "northeurope"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "app_subnet_prefixes" {
  description = "Address prefix for the application subnet"
  type        = list(string)
  default     = ["10.40.1.0/24"]
}

variable "data_subnet_prefixes" {
  description = "Address prefix for the data subnet"
  type        = list(string)
  default     = ["10.40.2.0/24"]
}
