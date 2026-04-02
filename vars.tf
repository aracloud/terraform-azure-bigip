locals {
  today-timestamp = timestamp()
  //cloudinit = templatefile("${path.module}/cloudinit.tpl", {
  //  f5_license_key = var.f5_license_key
  //})
}

variable "f5_license_key" {
  description = "eval byol license key"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "BIG-IP admin password"
  type        = string
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

# pool member backend ip address
variable "origin_ip1" {
  type = string
}


# azure docker node instance type
variable "docker-instance-type" {
  description = "instance type"
  type = string
}

# azure docker node disk type
variable "docker-storage-account-type" {
  description = "storage account type"
  type = string
}

# azure docker node user
variable "docker-node-user" {
  description = "docker user"
  type = string
}

# azure ssh public key
variable "docker-pub-key" {
  description = "public key on terraform machine"
  type = string
}

# azure docker node image reference
# (corresponds with custom-data.tpl)
variable "src_img_ref_docker" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

