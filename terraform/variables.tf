# Variables for DNS management
variable "manage_dns" {
  description = "Whether to manage DNS records in Route53 (set to true after migrating emelz.org to this account)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Base domain name for DNS records"
  type        = string
  default     = "emelz.org"
}

variable "rancher_subdomain" {
  description = "Subdomain for Rancher UI"
  type        = string
  default     = "rancher"
}

variable "dev_subdomain" {
  description = "Subdomain for development/demo applications"
  type        = string
  default     = "dev"
}