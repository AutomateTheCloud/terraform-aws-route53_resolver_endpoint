# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An inbound or outbound Route 53 Resolver endpoint with two or more IP addresses, keyed by names you choose, each in its own subnet and with an address AWS picks or one you set.
- A security group with no network access until you allow it: ingress rules for an inbound endpoint, egress rules for an outbound one, from or to IPv4 ranges, security groups and prefix lists, only on the ports the endpoint's protocols need.
- Plain DNS, DNS over HTTPS, and DNS over HTTPS with FIPS-validated cryptography.
- `region`, to create the endpoint in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for an inbound endpoint and an outbound endpoint with a forwarding rule.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-route53_resolver_endpoint/releases/tag/v1.0.0
