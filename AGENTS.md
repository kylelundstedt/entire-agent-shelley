# Agent guide — entire-agent-shelley

This repository contains the prototype Entire external-agent plugin for
Shelley. The executable contract is `entire-agent-shelley`; repository naming
must not change that discovery name.

## Scope

- Map Shelley `new-conversation`, `chat-message`, and `end-of-turn` hooks to
  Entire lifecycle events.
- Project the matching conversation directly from Shelley SQLite.
- Preserve existing Shelley hooks and fail open when this plugin or Entire is
  unavailable.
- Keep authoring content non-authoritative; this plugin records provenance and
  does not grant execution or promotion authority.

## Required checks

Before committing:

```bash
python3 -m py_compile entire-agent-shelley
ENTIRE_SKIP_REAL=1 bash test-shelley-live.sh
```

When Entire CLI is installed, also run:

```bash
bash test-shelley-live.sh
```

## Safety

Use synthetic fixtures only. Never put real credentials, borrower/customer
PII or NPPI, client-confidential material, privileged communications, or
license-restricted source content in tests, prompts, logs, or checkpoints.

Do not weaken repository registration, cross-repository checks, subagent
exclusion, hook preservation, failure isolation, lifecycle serialization,
mode-restricted state, or reasoning/tool-result exclusions merely to simplify
packaging.

## Compatibility and releases

- Update `VERSION` and `PLUGIN_VERSION` together.
- Record tested Shelley, Entire CLI, Python, and OS versions in release notes.
- Do not claim upstream Entire support unless the plugin is accepted there.
- Keep unsupported capabilities, including `write-session`, explicit.
