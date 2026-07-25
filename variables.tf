variable "name" {
  description = "Name of the virtual machine."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the virtual machine."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the virtual machine."
  type        = string
}

variable "size" {
  description = "SKU size of the virtual machine, e.g. Standard_B2s."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Administrator username for the virtual machine."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "OpenSSH-formatted public key granted access to the admin account."
  type        = string

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp(256|384|521)) [A-Za-z0-9+/]+=*( |$)", trimspace(var.admin_ssh_public_key)))
    error_message = "The admin_ssh_public_key must be a single OpenSSH public key, e.g. \"ssh-rsa AAAA... user@host\". Passing a file path or a private key is a common mistake."
  }
}

variable "network_interface_ids" {
  description = "List of network interface IDs to attach to the virtual machine. The first is primary."
  type        = list(string)

  validation {
    condition     = length(var.network_interface_ids) > 0
    error_message = "At least one network interface ID must be provided."
  }
}

variable "os_disk_caching" {
  description = "Caching mode of the OS disk. One of None, ReadOnly or ReadWrite."
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "The os_disk_caching must be one of None, ReadOnly or ReadWrite."
  }
}

variable "os_disk_storage_account_type" {
  description = "Storage account type of the OS disk, e.g. Standard_LRS or Premium_LRS."
  type        = string
  default     = "Premium_LRS"

  validation {
    condition = contains([
      "Standard_LRS",
      "StandardSSD_LRS",
      "StandardSSD_ZRS",
      "Premium_LRS",
      "Premium_ZRS",
    ], var.os_disk_storage_account_type)
    error_message = "The os_disk_storage_account_type must be one of Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_LRS or Premium_ZRS."
  }
}

variable "os_disk_disk_encryption_set_id" {
  description = "ID of the disk encryption set used to encrypt the OS disk with a customer-managed key. Null keeps Azure's platform-managed key, which still encrypts the disk at rest."
  type        = string
  default     = null
}

variable "encryption_at_host_enabled" {
  description = "Whether to encrypt the VM's temp disk and OS/data disk caches on the host. Requires the Microsoft.Compute/EncryptionAtHost feature to be registered on the subscription."
  type        = bool
  default     = false
}

variable "boot_diagnostics_enabled" {
  description = "Whether to enable boot diagnostics, which capture serial console output and boot screenshots for a VM that fails to start."
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_account_uri" {
  description = "Blob endpoint of the storage account used for boot diagnostics. Null uses the Azure-managed storage account, which requires no storage account of your own. Ignored when boot_diagnostics_enabled is false."
  type        = string
  default     = null
}

variable "source_image_reference" {
  description = "Marketplace image reference used to provision the virtual machine."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "tags" {
  description = "Map of tags applied to the virtual machine."
  type        = map(string)
  default     = {}
}
