# terraform-azurerm-virtual-machine

Terraform module that manages an [Azure](https://azure.microsoft.com/) Linux
virtual machine. It provisions a single VM from a marketplace image with
SSH-key authentication (password login disabled) and a managed OS disk, and
either attaches one or more pre-existing network interfaces or creates a single
network interface in a subnet you name.

The module never creates a public IP. Network exposure is determined by the
NICs you pass in, or, for the NIC the module creates, by the subnet and the
optional existing public IP you attach to it. Boot diagnostics are on by
default, and the OS disk supports a customer-managed key.

## Usage

```hcl
module "virtual_machine" {
  source = "github.com/moveeeax/terraform-azurerm-virtual-machine?ref=v1.0.0"

  name                = "app-vm"
  resource_group_name = "prod-rg"
  location            = "eastus"
  size                = "Standard_D2s_v5"

  admin_username       = "azureuser"
  admin_ssh_public_key = file("~/.ssh/id_rsa.pub")

  network_interface_ids = [module.nic.id]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

### Network interface

Set exactly one of `network_interface_ids` or `subnet_id`:

- `network_interface_ids` attaches NICs you manage yourself; the first is
  primary. Use it for several NICs, accelerated networking, custom DNS
  servers or anything else the module does not expose.
- `subnet_id` (with `network_interface_ids` left empty) makes the module create
  one NIC, named `<name>-nic` unless `network_interface_name` is set, with a
  single IP configuration in that subnet. The private IP is dynamic unless
  `private_ip_address` is set, and `public_ip_address_id` attaches an existing
  public IP.

```hcl
module "virtual_machine" {
  source = "github.com/moveeeax/terraform-azurerm-virtual-machine?ref=v1.2.0"

  name                = "app-vm"
  resource_group_name = "prod-rg"
  location            = "eastus"

  admin_ssh_public_key = file("~/.ssh/id_rsa.pub")

  subnet_id          = module.subnet.id
  private_ip_address = "10.0.1.10" # optional; omit for a dynamic IP
}
```

Whether the module creates a NIC is decided by `network_interface_ids` being
empty, not by `subnet_id`, so `subnet_id` may be the not-yet-known ID of a
subnet created in the same apply. Passing both, neither, or the NIC-only
inputs together with `network_interface_ids` fails at plan time.

Switching an existing VM from `network_interface_ids` to `subnet_id` (or back)
swaps the NIC the VM is attached to. Read the plan before applying it, and
prefer picking one mode per VM up front.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0, < 6.0 |

CI validates and tests the module against the 3.0.0 floor and the latest
azurerm 5.x release; 6.x is excluded until it has been tested.

## Inputs

| Name                           | Description                                                              | Type           | Default          | Required |
|--------------------------------|--------------------------------------------------------------------------|----------------|------------------|:--------:|
| `name`                         | Name of the virtual machine.                                             | `string`       | n/a              |   yes    |
| `resource_group_name`          | Name of the resource group in which to create the virtual machine.       | `string`       | n/a              |   yes    |
| `location`                     | Azure region in which to create the virtual machine.                     | `string`       | n/a              |   yes    |
| `size`                         | SKU size of the virtual machine.                                         | `string`       | `"Standard_B2s"` |    no    |
| `admin_username`               | Administrator username for the virtual machine.                          | `string`       | `"azureuser"`    |    no    |
| `admin_ssh_public_key`         | OpenSSH-formatted public key granted access to the admin account.        | `string`       | n/a              |   yes    |
| `network_interface_ids`        | Existing network interface IDs to attach. The first is primary. Leave empty to use `subnet_id`. | `list(string)` | `[]` | no |
| `subnet_id`                    | Subnet in which the module creates one NIC. Only when `network_interface_ids` is empty. | `string` | `null` | no |
| `network_interface_name`       | Name of the NIC the module creates. `null` uses `<name>-nic`.            | `string`       | `null`           |    no    |
| `private_ip_address`           | Static private IPv4 address of the NIC the module creates. `null` is dynamic. | `string`  | `null`           |    no    |
| `public_ip_address_id`         | Existing public IP attached to the NIC the module creates.               | `string`       | `null`           |    no    |
| `os_disk_caching`              | Caching mode of the OS disk. One of `None`, `ReadOnly`, `ReadWrite`.     | `string`       | `"ReadWrite"`    |    no    |
| `os_disk_storage_account_type` | Storage account type of the OS disk.                                     | `string`       | `"Premium_LRS"`  |    no    |
| `os_disk_disk_encryption_set_id` | Disk encryption set used to encrypt the OS disk with a customer-managed key. | `string`  | `null`           |    no    |
| `encryption_at_host_enabled`   | Encrypt the temp disk and OS/data disk caches on the host.               | `bool`         | `false`          |    no    |
| `boot_diagnostics_enabled`     | Enable boot diagnostics (serial console output and boot screenshots).    | `bool`         | `true`           |    no    |
| `boot_diagnostics_storage_account_uri` | Blob endpoint for boot diagnostics. `null` uses Azure-managed storage. | `string` | `null`         |    no    |
| `source_image_reference`       | Marketplace image reference used to provision the VM.                    | `object`       | Ubuntu 22.04 LTS |    no    |
| `tags`                         | Map of tags applied to the virtual machine.                              | `map(string)`  | `{}`             |    no    |

### Encryption at rest

Azure encrypts managed disks at rest with a platform-managed key unconditionally,
so no configuration is required for baseline encryption. Set
`os_disk_disk_encryption_set_id` when policy requires a customer-managed key, and
`encryption_at_host_enabled = true` to additionally encrypt the temp disk and the
disk caches on the host. The latter requires the `Microsoft.Compute/EncryptionAtHost`
feature to be registered on the subscription first:

```sh
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
```

## Outputs

| Name                 | Description                                              |
|----------------------|----------------------------------------------------------|
| `id`                 | ID of the virtual machine.                               |
| `name`               | Name of the virtual machine.                             |
| `private_ip_address` | Primary private IP address of the virtual machine.       |
| `public_ip_address`  | Primary public IP address of the virtual machine, if any.|
| `network_interface_id` | ID of the NIC created by the module, or `null` when `network_interface_ids` was passed. |
| `network_interface_ids` | IDs of all NICs attached to the virtual machine.       |

## Development

The module ships a `terraform test` suite that runs against a mocked provider,
so it needs no Azure credentials and no network access:

```sh
terraform init -backend=false
terraform test
```

`mock_provider` requires Terraform (or OpenTofu) >= 1.7. That is a test-only
requirement — the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
