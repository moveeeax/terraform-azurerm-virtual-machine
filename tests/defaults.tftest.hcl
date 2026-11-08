# Requires Terraform >= 1.7 / OpenTofu >= 1.7 for mock_provider. This is a
# test-only requirement; the module itself still supports >= 1.5.
#
# Run from the repository root with `terraform test`. No Azure credentials and
# no network access are needed — every provider call is mocked.

# The NIC ID is pinned to a well-formed one because azurerm_linux_virtual_machine
# validates the shape of network_interface_ids, and OpenTofu fills mocked
# attributes in during plan rather than leaving them unknown.
mock_provider "azurerm" {
  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/networkInterfaces/test-vm-nic"
    }
  }
}

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

run "existing_network_interfaces_are_attached_unchanged" {
  command = plan

  assert {
    condition     = length(azurerm_network_interface.this) == 0
    error_message = "No network interface may be created when network_interface_ids is set; existing deployments must plan the same."
  }

  assert {
    condition     = tolist(azurerm_linux_virtual_machine.this.network_interface_ids) == tolist(var.network_interface_ids)
    error_message = "The passed-in network interface IDs must be attached as-is."
  }
}

run "creates_a_network_interface_from_a_subnet" {
  command = plan

  variables {
    network_interface_ids = []
    subnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-snet"
  }

  assert {
    condition     = length(azurerm_network_interface.this) == 1
    error_message = "Exactly one network interface must be created when subnet_id is set."
  }

  assert {
    condition     = azurerm_network_interface.this[0].name == "test-vm-nic"
    error_message = "The network interface must default to the name \"<name>-nic\"."
  }

  assert {
    condition     = azurerm_network_interface.this[0].ip_configuration[0].subnet_id == var.subnet_id
    error_message = "The network interface must be placed in subnet_id."
  }

  assert {
    condition     = azurerm_network_interface.this[0].ip_configuration[0].private_ip_address_allocation == "Dynamic"
    error_message = "Without private_ip_address the private IP must be allocated dynamically."
  }

  assert {
    condition     = azurerm_network_interface.this[0].ip_configuration[0].public_ip_address_id == null
    error_message = "No public IP may be attached unless public_ip_address_id is set."
  }
}

run "created_network_interface_accepts_static_ip_and_public_ip" {
  command = plan

  variables {
    network_interface_ids  = []
    subnet_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-snet"
    network_interface_name = "custom-nic"
    private_ip_address     = "10.0.1.10"
    public_ip_address_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/publicIPAddresses/test-pip"
  }

  assert {
    condition     = azurerm_network_interface.this[0].name == "custom-nic"
    error_message = "network_interface_name must override the default NIC name."
  }

  assert {
    condition     = azurerm_network_interface.this[0].ip_configuration[0].private_ip_address_allocation == "Static"
    error_message = "Setting private_ip_address must switch allocation to Static."
  }

  assert {
    condition     = azurerm_network_interface.this[0].ip_configuration[0].private_ip_address == "10.0.1.10"
    error_message = "private_ip_address must be passed through to the network interface."
  }

  assert {
    condition     = azurerm_network_interface.this[0].ip_configuration[0].public_ip_address_id == var.public_ip_address_id
    error_message = "public_ip_address_id must be passed through to the network interface."
  }
}

run "rejects_neither_network_interface_ids_nor_subnet_id" {
  command = plan

  variables {
    network_interface_ids = []
  }

  expect_failures = [azurerm_linux_virtual_machine.this]
}

run "rejects_both_network_interface_ids_and_subnet_id" {
  command = plan

  variables {
    subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-snet"
  }

  expect_failures = [azurerm_linux_virtual_machine.this]
}

run "rejects_nic_settings_with_existing_network_interfaces" {
  command = plan

  variables {
    private_ip_address = "10.0.1.10"
  }

  expect_failures = [azurerm_linux_virtual_machine.this]
}

run "rejects_a_subnet_name_instead_of_an_id" {
  command = plan

  variables {
    network_interface_ids = []
    subnet_id             = "test-snet"
  }

  expect_failures = [var.subnet_id]
}

run "rejects_an_invalid_private_ip_address" {
  command = plan

  variables {
    network_interface_ids = []
    subnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-snet"
    private_ip_address    = "10.0.1.256"
  }

  expect_failures = [var.private_ip_address]
}

run "rejects_a_public_ip_name_instead_of_an_id" {
  command = plan

  variables {
    network_interface_ids = []
    subnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-snet"
    public_ip_address_id  = "test-pip"
  }

  expect_failures = [var.public_ip_address_id]
}
