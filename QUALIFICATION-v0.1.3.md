# v0.1.3 exeslim launcher qualification — 2026-08-17

## Purpose

Qualify the source-native Shelley plugin on the current minimal exe.dev image,
where Shelley runs with `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`
and Python is available only as the uv-managed user interpreter at
`~/.local/bin/python3`.

## Defect corrected

`v0.1.2` used `#!/usr/bin/env python3`. The managed hooks therefore failed open
before plugin code ran because Shelley's restricted service `PATH` contained no
Python interpreter. The existing synthetic restricted-PATH regression had been
qualified on a VM with `/usr/bin/python3`, so it did not model exeslim.

`v0.1.3` uses a shell/Python polyglot launcher. It resolves, in order:

1. `ENTIRE_SHELLEY_PYTHON`;
2. `~/.local/bin/python3`; and
3. `python3` on `PATH`.

The plugin remains one executable, and installed/managed copies retain the same
launcher behavior.

## Evidence

On `iv-foundry-stage2`:

- Entire CLI `0.8.42` was checksum-verified and installed;
- plugin compilation passed under Python 3.14;
- direct execution with `PATH=/usr/bin:/bin` resolved the user interpreter and
  reported plugin version `0.1.3`;
- the synthetic lifecycle suite passed with and without the real Entire CLI;
- hook preservation, restricted-PATH Entire discovery, lifecycle ordering,
  failure isolation, registration, commit condensation, checkpoint trailer,
  and checkpoint-ref transcript checks passed; and
- executable SHA-256 is
  `1541c304ce86e7b80b74d91a01348daa6a38dd53e068c856c3d832880a55f64e`.

No real credentials, provider data, PII/NPPI, client-confidential material, or
license-restricted source content was used.

## Disposition

`v0.1.3` supersedes `v0.1.2` for minimal Stage 2 authoring VMs. Install and
verify it before Fannie M4 authoring begins. Entire remains nonblocking
review-provenance capture; it does not enter executable identity or authority.
