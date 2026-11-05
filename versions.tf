terraform {
  required_version = ">= 1.5"

  required_providers {
    # Floor 3.0 and the latest 5.x are validated and tested in CI;
    # linux_virtual_machine is not affected by the 5.0 removals. 6.0 has not
    # been vetted.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 6.0"
    }
  }
}
