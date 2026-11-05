terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 6.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "virtual_machine" {
  source = "../.."

  name                = "example-vm"
  resource_group_name = "example-rg"
  location            = "eastus"
  size                = "Standard_B2s"

  admin_username = "azureuser"
  # Throwaway public key so the example plans as-is; replace it with your own,
  # e.g. admin_ssh_public_key = file("~/.ssh/id_rsa.pub")
  admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyts8GjHrd1XuwJLrDFn4IfQ2drzDviOVG6cldr4I1GGAIuFbkNbjisQ/kOve8pUjx/w0LkIh/bBvcv66FtcuJLXJeWDlzg1cHBdxu8Exsa3EvyFtaOyhLfqFkwaTvVV/3hKRIg+FGPXw1XiWQaVSaUJ+vICcsGWgOcCBslMINGVA9CzYQzMjcnOCqlVeVWaI+RejnnS2W0eyk/QYoeOCw67Hx175+prnwYDge8VxLROfdg6JBS146SJiQQmeBTJSAOMSkZepXBC9y4m6Q+4VTk+/D5ApRV5SdFgFcygkzM40NqgN4TTlPZipNAdiKpapDvTWr1xWfo9/+asjduc+L example@terraform-azurerm-virtual-machine"

  network_interface_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/networkInterfaces/example-nic"]

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "vm_id" {
  value = module.virtual_machine.id
}
