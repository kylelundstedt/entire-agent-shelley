# QUALIFICATION v0.1.0 — exe.dev VM

Date: 2026-07-26 UTC
VM: `iv-entire-agent-shelley`
Verdict: **READY for Stage 2 authoring VM installation**

## Checked artifact

- Tag: `v0.1.0`
- Commit: `e7c0008`
- Executable SHA-256: `3aea8c21fb65537cce7e3cb3606098e8ad487e14e1d141a0401394d7de66b31b`
- `sha256sum -c SHA256SUMS`: PASS (`entire-agent-shelley: OK`)
- `~/.local/bin/entire-agent-shelley version`: `{"name":"entire-agent-shelley","version":"0.1.0"}`

## Environment versions

```text
uname -a
Linux iv-entire-agent-shelley 6.12.93 #1 SMP Wed Jul 22 19:44:49 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux

python3 --version
Python 3.12.3

shelley version
{
  "version": "0.877.970765614",
  "tag": "v0.877.970765614",
  "commit": "e3eb8cd7e8e04247a91e65789838c9a993f974b8",
  "commit_time": "2026-07-26T15:01:39Z"
}

entire version
Entire CLI 0.8.42
Go version: go1.26.4
OS/Arch: linux/amd64

git --version
git version 2.43.0
```

Entire CLI was initially absent and was installed using the documented Linux installer:

```bash
curl -fsSL https://entire.io/install.sh | bash
```

No tokens, PATs, SSH keys, or other credentials were added. Project telemetry was disabled with `--telemetry=false`.

## Commands and results

```bash
git clone https://github.int.exe.xyz/kylelundstedt/entire-agent-shelley.git \
  /home/exedev/entire-agent-shelley
# Destination already existed from the VM environment, so origin/main and tags were fetched instead.

git fetch origin main --prune
git reset --hard origin/main
git fetch --tags origin
git checkout v0.1.0
sha256sum -c SHA256SUMS
git rev-parse --short HEAD
sha256sum entire-agent-shelley
```

Result: PASS. Checkout was exactly `v0.1.0` at `e7c0008`; checksum matched.

```bash
make test
```

Result: PASS.

```text
python3 -m py_compile entire-agent-shelley
bash -n install.sh uninstall.sh test-shelley-live.sh
ENTIRE_SKIP_REAL=1 bash test-shelley-live.sh
SKIP: real Entire lifecycle integration
PASS: direct Shelley live Entire plugin
```

```bash
make test-real
```

Result: PASS.

```text
python3 -m py_compile entire-agent-shelley
bash -n install.sh uninstall.sh test-shelley-live.sh
bash test-shelley-live.sh
  ✓ Created orphan ref entire/checkpoints/v1 for session metadata
PASS: direct Shelley live Entire plugin
```

```bash
./install.sh
~/.local/bin/entire-agent-shelley version
stat -c '%a %n' ~/.local/bin/entire-agent-shelley \
  ~/.local/share/entire-agent-shelley \
  ~/.local/share/entire-agent-shelley/install.json
cat ~/.local/share/entire-agent-shelley/install.json
```

Result: PASS.

```text
installed entire-agent-shelley 0.1.0 to /home/exedev/.local/bin/entire-agent-shelley
sha256 3aea8c21fb65537cce7e3cb3606098e8ad487e14e1d141a0401394d7de66b31b
{"name":"entire-agent-shelley","version":"0.1.0"}
755 /home/exedev/.local/bin/entire-agent-shelley
700 /home/exedev/.local/share/entire-agent-shelley
600 /home/exedev/.local/share/entire-agent-shelley/install.json
```

Receipt:

```json
{
  "name": "entire-agent-shelley",
  "version": "0.1.0",
  "destination": "/home/exedev/.local/bin/entire-agent-shelley",
  "sha256": "3aea8c21fb65537cce7e3cb3606098e8ad487e14e1d141a0401394d7de66b31b"
}
```

## Live synthetic qualification

A disposable private local Git repository and disposable Shelley home were created under `/tmp/qual-v010-pass.IlKHX4`. The Shelley server was run with the built-in predictable model only and LLM integration disabled:

```bash
shelley -predictable-only -disable-llm-integration \
  -db /tmp/qual-v010-pass.IlKHX4/home/.config/shelley/shelley.db \
  serve \
  -socket /tmp/qual-v010-pass.IlKHX4/home/.config/shelley/shelley.sock \
  -port 0 \
  -port-file /tmp/qual-v010-pass.IlKHX4/port
```

Entire capture was enabled from the synthetic repository with telemetry disabled:

```bash
entire enable --agent shelley --project --telemetry=false --checkpoint-backend branch
```

Result: PASS.

```text
Agent: Shelley
Installed 3 hooks for Shelley direct SQLite adapter with live lifecycle hooks (Preview)
✓ Configured project
  .entire/settings.json
✓ Created orphan ref entire/checkpoints/v1 for session metadata
Ready.
```

Synthetic Shelley client turns:

```bash
shelley client -url unix:///tmp/qual-v010-pass.IlKHX4/home/.config/shelley/shelley.sock \
  chat -model predictable -cwd /tmp/qual-v010-pass.IlKHX4/repo \
  -p 'Synthetic qualification turn one only. Reply with a synthetic status.'

shelley client -url unix:///tmp/qual-v010-pass.IlKHX4/home/.config/shelley/shelley.sock \
  chat -c cUIYKQI \
  -p 'Synthetic qualification turn two only. Reply with a synthetic status.'

shelley client -url unix:///tmp/qual-v010-pass.IlKHX4/home/.config/shelley/shelley.sock \
  chat -c cUIYKQI \
  -p 'Synthetic qualification queued turn three only. Reply with a synthetic status.'
```

Result: PASS.

- Synthetic Shelley conversation ID: `cUIYKQI`
- Observed Shelley `end-of-turn hook applied` count for conversation: `3`
- Lifecycle state after turns: `{"active":false,"pending":[]}`
- Preserved synthetic hooks invoked: `new-conversation;end-of-turn;end-of-turn;end-of-turn;`
- The transcript contained turn-one, turn-two, and queued turn-three synthetic prompts.

Synthetic checkpoint result:

```text
commit=1afbeabb3d09a17e8ddf490b151d3b48c9f4269d
commit body:
synthetic live qualification change

Entire-Checkpoint: db20376a915c
checkpoint_ref=2792593e3267652a52d7411dc6378252dc45b8e2
transcript_path=db/20376a915c/0/transcript.jsonl
```

`entire/checkpoints/v1` contained the transcript, and the transcript contained the synthetic Shelley conversation.

Clean clone verification:

```bash
git clone /tmp/qual-v010-pass.IlKHX4/repo /tmp/qual-v010-pass.IlKHX4/clone
git -C /tmp/qual-v010-pass.IlKHX4/clone fetch origin entire/checkpoints/v1:entire/checkpoints/v1
cd /tmp/qual-v010-pass.IlKHX4/clone
entire checkpoint list --no-pager
entire checkpoint explain db20376a915c
```

Result: PASS.

```text
branch       master
checkpoints  1

● db20376a915c  "Synthetic qualification turn one only. Reply with a synth..."
  07-26 19:38 (1afbeab) synthetic live qualification change
```

`entire checkpoint explain db20376a915c` reconstructed the checkpoint from Git and displayed the synthetic transcript for session `cUIYKQI`.

## Checklist coverage

1. new conversation produced `SessionStart` and initial `TurnStart`: PASS (`make test-real`, live Entire logs).
2. `end-of-turn` produced `TurnEnd` and SQLite projection: PASS (`make test-real`, live transcript from Shelley SQLite).
3. At least two sequential real Shelley turns: PASS (`cUIYKQI`, three turns observed).
4. Queued/overlapping prompt did not overtake preceding `TurnEnd`: PASS (`make test-real`; live lifecycle ended with no pending events).
5. Existing synthetic Shelley hooks preserved and restored: PASS (`make test-real`; live preserved hooks invoked).
6. Unregistered repository did not dispatch capture: PASS (`make test-real`).
7. Entire absence/plugin launch failure did not block Shelley: PASS (`make test-real`).
8. Preserved-hook failure still propagated: PASS (`make test-real`).
9. Commit condensation added `Entire-Checkpoint`: PASS (`db20376a915c`).
10. `entire/checkpoints/v1` contained transcript: PASS (`db/20376a915c/0/transcript.jsonl`).
11. Clean clone reconstructed and verified checkpoint from Git: PASS.
12. No fixture/hook/session/cache/Entire state escaped disposable home/repositories: PASS. Synthetic fixture directories were removed after recording these results; installed plugin files remain as expected from `./install.sh`.

## State leakage and safety

- Synthetic data only.
- No real credentials, PII/NPPI, client-confidential, privileged, or license-restricted content used.
- Telemetry disabled in `.entire/settings.json`.
- Fixture roots used: `/tmp/qual-v010-pass.IlKHX4` and earlier failed-smoke `/tmp/qual-v010-*` roots; all were removed after report capture.
- Persistent installation state intentionally left by `./install.sh`:
  - `/home/exedev/.local/bin/entire-agent-shelley`
  - `/home/exedev/.local/share/entire-agent-shelley/install.json`

## Readiness verdict

`v0.1.0` passes qualification on `iv-entire-agent-shelley` and is ready for installation on Stage 2 authoring VMs.
