locals {
  # The module creates its own network interface only when no existing NIC IDs
  # are passed in. This keys off the length of the list, which is known at plan
  # time even when the IDs themselves are not, rather than off subnet_id, which
  # is often the not-yet-known ID of a subnet created in the same apply and
  # would make `count` unresolvable.
  create_network_interface = length(var.network_interface_ids) == 0
}

resource "azurerm_network_interface" "this" {
  count = local.create_network_interface ? 1 : 0

  name                = coalesce(var.network_interface_name, "${var.name}-nic")
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.public_ip_address_id
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  # The default (Standard_B2s) is on the azurerm tflint ruleset's
  # retired/announced-for-retirement list. Changing the default would resize
  # existing callers' VMs, so it is kept until the next major release.
  # tflint-ignore: azurerm_linux_virtual_machine_retired_size
  size           = var.size
  admin_username = var.admin_username

  # Set explicitly rather than relying on the provider default so the module's
  # documented "SSH keys only" contract cannot change underneath it.
  disable_password_authentication = true

  # Encrypts the VM's temp disk and the OS/data disk caches on the host itself.
  # Off by default because it requires the Microsoft.Compute/EncryptionAtHost
  # feature to be registered on the subscription first.
  encryption_at_host_enabled = var.encryption_at_host_enabled

  network_interface_ids = local.create_network_interface ? [azurerm_network_interface.this[0].id] : var.network_interface_ids

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

  # Cross-variable checks live here rather than in variable validation blocks
  # because those can only reference other variables from Terraform 1.9, and
  # the module supports >= 1.5.
  lifecycle {
    precondition {
      condition     = local.create_network_interface == (var.subnet_id != null)
      error_message = "Set exactly one of network_interface_ids (attach existing NICs) or subnet_id (the module creates one NIC)."
    }

    precondition {
      condition     = local.create_network_interface || (var.private_ip_address == null && var.public_ip_address_id == null && var.network_interface_name == null)
      error_message = "private_ip_address, public_ip_address_id and network_interface_name only apply to the NIC the module creates; leave them unset when passing network_interface_ids."
    }
  }
}
