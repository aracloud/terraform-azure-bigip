locals {
  today-timestamp = timestamp()
}


#########################
# Variablen (Passe hier an)
#########################

variable "f5_license_key" {
  description = "Dein F5 BYOL Lizenzschlüssel"
  type        = string
  // sensitive   = true
  default = "OWRFG-OEAZN-JQFVI-NSOKU-LUOTGFU"
  // default = "LXINY-FSZDI-UOGXU-KUCHW-KTDYHPG"
}

variable "admin_password" {
  description = "Admin Passwort für BIG-IP"
  type        = string
  default     = "P@ssw0rd1234!"
}

variable "prefix" {
  description = "prefix for created objects"
  type = string
}

variable "azure-location" {
  description = "azure location to run the deployment"
  type = string
}

# tag: source "git" for azure resource group 
variable "tag_source_git" {
  type = string
}

# tag: owner azure resource group
variable "tag_owner" {
  type = string
}

# tag: source "host" for azure resource group 
variable "tag_source_host" {
  type = string
}