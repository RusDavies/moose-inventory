# Package provenance hardening evaluation

Status: evaluated as future hardening, not a current release requirement.

Moose Inventory publishes the `moose-inventory` RubyGem through GitHub Actions and RubyGems trusted publishing. This document records the current package-provenance evaluation so release decisions do not confuse useful future hardening with a present release blocker.

## Current baseline

The approved release baseline is:

- releases start from reviewed `v*` tags;
- the GitHub `release` environment requires human review by `RusDavies`;
- the release workflow verifies that the pushed tag matches `Moose::Inventory::VERSION`;
- the release workflow runs `MOOSE_INVENTORY_REQUIRE_SECURITY_TOOLS=1 ./scripts/check.sh`;
- RubyGems trusted publishing/OIDC issues a short-lived publish token to the reviewed workflow;
- no long-lived RubyGems API token is required in GitHub secrets;
- `scripts/ci/package_sanity.sh` builds and inspects the gem payload before release.

This is adequate for the current project profile: a Ruby CLI/RubyGem maintained by Russ, with no current security-sensitive consumer requirement for separately signed provenance artifacts.

## Options evaluated

### RubyGems trusted publishing/OIDC

Decision: keep as the required baseline.

Strengths:

- avoids long-lived RubyGems publishing secrets in GitHub;
- binds publishing to the repository, workflow, environment, and tag-triggered release path;
- fits the current RubyGems-native release process;
- already verified with release `v2.0` / gem `2.0`.

Limitations:

- proves the publish path, not a separately downloadable signed software bill of materials or artifact attestation;
- consumers still rely on RubyGems distribution metadata and the source repository release evidence.

### Checksums for built gems

Decision: useful as low-complexity future release evidence, but not currently required.

Possible implementation:

- build the gem in the release workflow;
- compute `sha256sum` for the `.gem` artifact;
- publish the checksum as a GitHub release artifact or release note after the gem publish succeeds.

Tradeoffs:

- simple and understandable;
- helps consumers compare a downloaded gem against release evidence;
- does not by itself prove who built or approved the artifact unless paired with workflow provenance.

### GitHub artifact attestations

Decision: promising future hardening, but defer until there is a consumer or policy need.

Possible implementation:

- grant the release workflow the minimum attestation permission required by GitHub;
- generate an attestation for the built `.gem` artifact before or during publish;
- document consumer verification commands.

Tradeoffs:

- stronger provenance signal than a bare checksum;
- adds GitHub-specific release machinery and consumer education;
- needs careful validation with RubyGems release tooling so the attested artifact is exactly the published gem.

### Sigstore / cosign-style detached signatures

Decision: not currently recommended.

Tradeoffs:

- can provide ecosystem-neutral signatures;
- introduces extra tooling, keyless identity semantics or key-management questions, and support burden;
- RubyGems consumers do not universally expect or verify these signatures.

### RubyGems gem signing with certificates

Decision: not currently recommended.

Tradeoffs:

- RubyGems has historic support for signed gems;
- practical adoption and verification are limited;
- certificate/key management would add risk and maintenance overhead disproportionate to current needs.

### SBOM generation

Decision: defer.

Tradeoffs:

- useful if enterprise consumers request dependency inventory evidence;
- adds format, generation, storage, and review questions;
- current dependency-audit controls already query OSV and bundler-audit from `Gemfile.lock` during release gates.

## Recommendation

Do not make additional package provenance a release blocker now.

Keep RubyGems trusted publishing/OIDC as the release baseline and revisit stronger provenance when one of these triggers occurs:

- a consumer requests verifiable artifact provenance, SBOMs, checksums, or signatures;
- Moose Inventory becomes part of a more security-sensitive deployment path;
- release policy changes require artifact attestations;
- the project starts publishing multiple binary/native artifacts rather than a source RubyGem;
- GitHub/RubyGems provenance tooling becomes simple enough to adopt with low operational burden.

If the trigger occurs, the preferred first hardening step is GitHub artifact attestation plus a published SHA-256 checksum for the exact built `.gem`, because that balances verification value against operational complexity. Sigstore/cosign, RubyGems certificate signing, and SBOM publication should remain second-stage options unless a consumer specifically needs them.

## Non-goals

This evaluation does not approve:

- changing the GitHub release workflow;
- publishing a new gem release;
- adding new GitHub permissions;
- adding or rotating signing keys;
- changing RubyGems settings;
- making public compliance or supply-chain-security claims.

Those actions require separate approval and verification.
