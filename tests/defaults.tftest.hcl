# Requires Terraform >= 1.7 / OpenTofu >= 1.7 for mock_provider. This is a
# test-only requirement; the module itself still supports >= 1.5.
#
# Run from the repository root with `terraform test`. No Azure credentials and
# no network access are needed — every provider call is mocked.

mock_provider "azurerm" {}

variables {
  name                  = "test-vm"
  resource_group_name   = "test-rg"
  location              = "eastus"
  admin_ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyts8GjHrd1XuwJLrDFn4IfQ2drzDviOVG6cldr4I1GGAIuFbkNbjisQ/kOve8pUjx/w0LkIh/bBvcv66FtcuJLXJeWDlzg1cHBdxu8Exsa3EvyFtaOyhLfqFkwaTvVV/3hKRIg+FGPXw1XiWQaVSaUJ+vICcsGWgOcCBslMINGVA9CzYQzMjcnOCqlVeVWaI+RejnnS2W0eyk/QYoeOCw67Hx175+prnwYDge8VxLROfdg6JBS146SJiQQmeBTJSAOMSkZepXBC9y4m6Q+4VTk+/D5ApRV5SdFgFcygkzM40NqgN4TTlPZipNAdiKpapDvTWr1xWfo9/+asjduc+L example@terraform-azurerm-virtual-machine"
  network_interface_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkInterfaces/test-nic"]
}

run "defaults_are_safe" {
  assert {
    condition     = azurerm_linux_virtual_machine.this.disable_password_authentication == true
    error_message = "Password authentication must be disabled; the module authenticates with SSH keys only."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.this.admin_ssh_key) == 1
    error_message = "Exactly one admin SSH key must be configured."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.this.boot_diagnostics) == 1
    error_message = "Boot diagnostics must be enabled by default so a VM that fails to boot can be diagnosed."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.boot_diagnostics[0].storage_account_uri == null
    error_message = "Boot diagnostics must default to the Azure-managed storage account."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.os_disk[0].storage_account_type == "Premium_LRS"
    error_message = "The OS disk must default to Premium_LRS."
  }
}

run "boot_diagnostics_can_be_disabled" {
  variables {
    boot_diagnostics_enabled = false
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.this.boot_diagnostics) == 0
    error_message = "Setting boot_diagnostics_enabled = false must remove the boot_diagnostics block."
  }
}

run "boot_diagnostics_accepts_a_custom_storage_account" {
  variables {
    boot_diagnostics_storage_account_uri = "https://examplediag.blob.core.windows.net/"
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.boot_diagnostics[0].storage_account_uri == "https://examplediag.blob.core.windows.net/"
    error_message = "A custom boot diagnostics storage account URI must be passed through."
  }
}

run "customer_managed_key_is_passed_through" {
  variables {
    os_disk_disk_encryption_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Compute/diskEncryptionSets/test-des"
    encryption_at_host_enabled     = true
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.os_disk[0].disk_encryption_set_id == var.os_disk_disk_encryption_set_id
    error_message = "The OS disk encryption set ID must be applied to the OS disk."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.this.encryption_at_host_enabled == true
    error_message = "encryption_at_host_enabled must be applied to the virtual machine."
  }
}

run "rejects_invalid_os_disk_caching" {
  command = plan

  variables {
    os_disk_caching = "ReadWriteMaybe"
  }

  expect_failures = [var.os_disk_caching]
}

run "rejects_invalid_os_disk_storage_account_type" {
  command = plan

  variables {
    os_disk_storage_account_type = "Ultra_LRS"
  }

  expect_failures = [var.os_disk_storage_account_type]
}

run "rejects_a_private_key_as_the_public_key" {
  command = plan

  variables {
    admin_ssh_public_key = "-----BEGIN OPENSSH PRIVATE KEY-----"
  }

  expect_failures = [var.admin_ssh_public_key]
}

run "rejects_an_empty_network_interface_list" {
  command = plan

  variables {
    network_interface_ids = []
  }

  expect_failures = [var.network_interface_ids]
}
