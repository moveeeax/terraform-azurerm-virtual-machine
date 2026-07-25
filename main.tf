resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.size
  admin_username      = var.admin_username

  # Set explicitly rather than relying on the provider default so the module's
  # documented "SSH keys only" contract cannot change underneath it.
  disable_password_authentication = true

  # Encrypts the VM's temp disk and the OS/data disk caches on the host itself.
  # Off by default because it requires the Microsoft.Compute/EncryptionAtHost
  # feature to be registered on the subscription first.
  encryption_at_host_enabled = var.encryption_at_host_enabled

  network_interface_ids = var.network_interface_ids

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type

    # null keeps Azure's platform-managed key (SSE); set to use a customer-managed key.
    disk_encryption_set_id = var.os_disk_disk_encryption_set_id
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  # Without this block Azure records no serial console output or boot screenshots,
  # which makes a VM that fails to boot effectively undiagnosable.
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_enabled ? [1] : []

    content {
      # null selects the Azure-managed storage account.
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  tags = var.tags
}
