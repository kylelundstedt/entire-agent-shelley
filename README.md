# entire-agent-shelley

Private-preview [Entire](https://entire.io/) external-agent plugin for
[Shelley](https://exe.dev/docs/shelley/intro.md).

The plugin captures Git-linked authoring context directly from Shelley's local
SQLite history. It is IV-authored and is **not yet shipped or supported by
Entire**.

## Status

- Plugin version: `0.1.1`
- Entire external-agent protocol: `v1`
- Qualified Entire CLI: `0.8.42`
- Platform: Linux
- Language/runtime: Python 3.11+
- Rewind/write-back: unsupported
- Shelley `SessionEnd`: unavailable; capture finalizes per turn

The implementation originated in IndustryVault's `iv-docs` Spike 23. Its source
history was extracted rather than squashed; the first standalone live-plugin
commit corresponds to `iv-docs` commit `7d75e2d`.

## Lifecycle

| Shelley hook       | Entire event(s)                     |
| ------------------ | ----------------------------------- |
| `new-conversation` | `SessionStart`, initial `TurnStart` |
| `chat-message`     | `TurnStart`                         |
| `end-of-turn`      | `TurnEnd`                           |

At turn end, the plugin opens Shelley SQLite read-only, begins a read
transaction, validates repository and subagent scope, and atomically
materializes an Entire-compatible JSONL transcript.

Overlapping and queued prompts are serialized per conversation. If a new prompt
arrives before Shelley's asynchronous prior `end-of-turn`, the plugin stores a
bounded mode-0600 pending lifecycle payload and releases its `TurnStart` only
after the preceding `TurnEnd`.

## Privacy boundary

The projection includes visible user messages, assistant responses, tool names
and inputs, timestamps, model identity, and repository-relative file
attribution where detectable. It excludes by default:

- Shelley system-message rows;
- model reasoning and encrypted reasoning payloads;
- subagent conversations;
- messages excluded from context;
- tool-result bodies.

These controls minimize capture; they are not DLP or a redaction guarantee. Do
not use the plugin with real credentials, PII/NPPI, client-confidential,
privileged, or license-restricted authoring content unless an independently
approved operating envelope permits it.

## Install

Install the executable without coupling runtime hooks to a Git checkout:

```bash
./install.sh
```

Then, from each private repository approved for capture:

```bash
entire enable --agent shelley --project --telemetry=false \
  --checkpoint-backend branch
```

The plugin installs global Shelley dispatchers but maintains an explicit set of
registered Git repositories. Disabling/removing one repository does not remove
the shared hooks while another registration remains.

Existing executable Shelley hooks are preserved, invoked first, and restored
after the final repository unregisters. The plugin installs a stable runtime
copy under `~/.config/entire/shelley-hooks/`, so changing or deleting the source
checkout does not break managed hooks.

## Uninstall

First disable or unregister Shelley capture from every repository that uses it.
Then run:

```bash
./uninstall.sh
```

The uninstaller refuses to remove an executable whose bytes no longer match the
installation receipt unless `--force` is explicitly supplied.

## Test

Protocol, hook, lifecycle, registration, SQLite, and fail-open tests with
synthetic fixtures:

```bash
ENTIRE_SKIP_REAL=1 bash test-shelley-live.sh
```

Full persistent-checkpoint qualification when Entire CLI is installed:

```bash
bash test-shelley-live.sh
```

The full test verifies commit condensation, the `Entire-Checkpoint` trailer,
and transcript persistence on `entire/checkpoints/v1`.

## Known limitations

- No Shelley `SessionEnd`; conversations are resumable and checkpoint per turn.
- `write-session` and rewind/restoration into Shelley SQLite are unsupported.
- File attribution is best-effort and does not infer every shell-command side
  effect.
- Pending lifecycle payloads are local transient authoring context and must be
  governed accordingly.
- Real Codex/Claude capture is outside this plugin; use their native Entire
  integrations and a separate reconciliation path.

## Development

See [`AGENTS.md`](AGENTS.md). This repository is intentionally focused on the
Shelley plugin; IndustryVault's provider-neutral ACR policy, threat model, and
AgentsView fallback remain in `kylelundstedt/iv-docs`.
