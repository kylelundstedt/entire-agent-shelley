# v0.1.0 qualification — exe.dev

Run this checklist on the dedicated `iv-entire-agent-shelley` VM. Use only
synthetic fixtures and the repository-scoped exe.dev GitHub integration.

## Prepare

```bash
git clone https://github.int.exe.xyz/kylelundstedt/entire-agent-shelley.git \
  /home/exedev/entire-agent-shelley
cd /home/exedev/entire-agent-shelley
git checkout v0.1.0
sha256sum -c SHA256SUMS
```

Read `AGENTS.md` before changing anything. Confirm the checkout is exactly tag
`v0.1.0` at commit `e7c0008` and the executable checksum is
`3aea8c21fb65537cce7e3cb3606098e8ad487e14e1d141a0401394d7de66b31b`.

## Environment

Record, without exposing credentials:

```bash
uname -a
python3 --version
shelley version
entire version
```

If Entire CLI is absent, install it through its documented Linux installation
method. Disable telemetry. Do not add tokens, PATs, SSH keys, or other secrets
to the VM.

## Test and install

```bash
make test
make test-real
./install.sh
~/.local/bin/entire-agent-shelley version
```

Verify the installation receipt and executable are mode-restricted as designed.
Do not enable capture in a repository containing sensitive content.

## Live synthetic qualification

Create a disposable private local Git repository and disposable Shelley
conversation containing only synthetic text. Enable branch-backed Entire
capture with telemetry disabled, then exercise lifecycle through the installed
Shelley hooks—not by calling `entire hooks` directly.

Verify:

1. new conversation → `SessionStart` and initial `TurnStart`;
2. `end-of-turn` → `TurnEnd` and transactional SQLite projection;
3. at least two sequential real Shelley turns;
4. queued/overlapping prompts cannot overtake the preceding `TurnEnd`;
5. an existing synthetic Shelley hook is preserved and restored;
6. an unregistered repository does not dispatch capture;
7. Entire absence or plugin launch failure does not block Shelley;
8. a preserved-hook failure still propagates;
9. commit condensation adds `Entire-Checkpoint`;
10. `entire/checkpoints/v1` contains the transcript;
11. a clean clone can reconstruct and verify the checkpoint from Git;
12. no fixture, hook, session, cache, or Entire state escaped the disposable
    home and repositories.

Do not test with real credentials, PII/NPPI, client-confidential, privileged, or
license-restricted content.

## Report

Commit no fixture state. Report:

- exact OS, Python, Shelley, Entire CLI, and plugin versions;
- commands run and pass/fail results;
- checkpoint ID and Git commit IDs from synthetic fixtures only;
- any state leakage, ordering, install/uninstall, or failure-isolation issue;
- whether `v0.1.0` is ready for installation on Stage 2 authoring VMs.

If a defect is found, work on `main`, add a regression test, bump the preview
version, and do not move or replace `v0.1.0`.
