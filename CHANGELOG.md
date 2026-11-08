# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-08

### Added

- Optional module-managed network interface: leave `network_interface_ids`
  empty and set `subnet_id` to have the module create one
  `azurerm_network_interface` with a single IP configuration in that subnet.
  `private_ip_address` makes the IP static, `public_ip_address_id` attaches an
  existing public IP, and `network_interface_name` overrides the default
  `<name>-nic`.
- Outputs `network_interface_id` (the NIC created by the module, or `null`) and
  `network_interface_ids` (every NIC attached to the VM).

### Changed

- `network_interface_ids` is now optional and defaults to `[]`. Setting both or
  neither of `network_interface_ids` and `subnet_id` is rejected by a
  precondition on the VM instead of the old variable validation. Configurations
  that pass `network_interface_ids` plan exactly as before.

## [1.1.0] - 2026-11-05

See the [GitHub release](https://github.com/moveeeax/terraform-azurerm-virtual-machine/releases/tag/v1.1.0).

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-virtual-machine/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-azurerm-virtual-machine/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-virtual-machine/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-virtual-machine/tree/v1.0.0
