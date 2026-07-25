# terraform-azurerm-virtual-machine

Terraform module that manages an [Azure](https://azure.microsoft.com/) Linux
virtual machine. It provisions a single VM from a marketplace image with
SSH-key authentication (password login disabled) and a managed OS disk, and
attaches one or more pre-existing network interfaces.

The module creates no public IP and no network interface of its own — network
exposure is entirely determined by the NICs you pass in. Boot diagnostics are
on by default, and the OS disk supports a customer-managed key.

## Usage

```hcl
module "virtual_machine" {
  source = "github.com/moveeeax/terraform-azurerm-virtual-machine"

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

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0, < 5.0 |

## Inputs

| Name                           | Description                                                              | Type           | Default          | Required |
|--------------------------------|--------------------------------------------------------------------------|----------------|------------------|:--------:|
| `name`                         | Name of the virtual machine.                                             | `string`       | n/a              |   yes    |
| `resource_group_name`          | Name of the resource group in which to create the virtual machine.       | `string`       | n/a              |   yes    |
| `location`                     | Azure region in which to create the virtual machine.                     | `string`       | n/a              |   yes    |
| `size`                         | SKU size of the virtual machine.                                         | `string`       | `"Standard_B2s"` |    no    |
| `admin_username`               | Administrator username for the virtual machine.                          | `string`       | `"azureuser"`    |    no    |
| `admin_ssh_public_key`         | OpenSSH-formatted public key granted access to the admin account.        | `string`       | n/a              |   yes    |
| `network_interface_ids`        | List of network interface IDs to attach. The first is primary.           | `list(string)` | n/a              |   yes    |
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
