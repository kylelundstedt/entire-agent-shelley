# v0.1.3 re-qualification against Entire CLI 0.10.1 — 2026-08-19

## Purpose

Qualify the unchanged `entire-agent-shelley` v0.1.3 plugin against **Entire CLI
0.10.1**, so the consuming provisioner (iv-provision) can bump its CLI pin from
0.8.42. The plugin and CLI speak a fixed protocol (the `info` hook-name set and
the lifecycle JSON); a CLI bump that skips a minor must be re-qualified, not
assumed. The prior pin 0.8.42 → 0.10.1 skips 0.9.x entirely.

The plugin is **not modified**: this qualifies v0.1.3 (tag `v0.1.3`,
commit `c467bd7`, executable SHA-256
`1541c304ce86e7b80b74d91a01348daa6a38dd53e068c856c3d832880a55f64e`) as-is.

## Environment

Run on the dedicated `iv-entire-agent-shelley` VM.

- `Linux x86_64`
- Python `3.14.6` (uv-managed user interpreter)
- Shelley `0.959.914757635`
- Test CLI `Entire CLI 0.10.1`, fetched from the release and checksum-verified
  (`entire_linux_amd64.tar.gz` =
  `eb669fde314a70e5b4bbad21c1c145324816431f125fd2ec01c9e163506f2881`)

The CLI under test was installed to a scratch directory and prepended to `PATH`
for the suite only; the VM's own pinned `~/.local/bin/entire` (0.8.42) was left
untouched and confirmed unchanged before and after.

Environment note: unlike `iv-foundry-stage2` (where v0.1.3 was first qualified,
with **no** system python on the restricted service PATH), this VM does have
`/usr/bin/python3` on `PATH=/usr/bin:/bin`. The v0.1.3 polyglot launcher's
interpreter resolution therefore was not stress-tested here for the
no-system-python case; that condition remains covered by QUALIFICATION-v0.1.3.md.
This run qualifies the plugin↔CLI protocol against 0.10.1, which is what the
version bump turns on.

## Evidence

Plugin cloned at tag `v0.1.3`; `sha256sum -c SHA256SUMS` passed.

- `check` — `py_compile` of the plugin and `bash -n` of the scripts: **ok**
- `test` (`ENTIRE_SKIP_REAL=1`, no real CLI): **PASS**
- `test-real` (against Entire CLI **0.10.1**): **PASS**, including real
  checkpoint condensation — the suite reported
  `Created orphan ref entire/checkpoints/v1 for session metadata`, and the
  transcript, commit trailer, and clean-clone reconstruction assertions passed.

Entire CLI **0.10.0** was qualified identically (same suite, same result:
**PASS**) on the same day. Because both stable releases pass, release age was not
the deciding factor; the consuming provisioner pins **0.10.1** as the newer
stable, completing the two-minor jump in one qualified step.

No real credentials, provider data, PII/NPPI, client-confidential material, or
license-restricted source content was used. Fixtures were disposable and
synthetic; no fixture state was committed.

## Disposition

`entire-agent-shelley` v0.1.3 is qualified against Entire CLI **0.10.1** (and
0.10.0). The plugin remains unchanged. Entire remains nonblocking
authoring-context capture; it does not enter executable identity or authority.
