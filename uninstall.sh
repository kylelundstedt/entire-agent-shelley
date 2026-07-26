#!/bin/bash
set -euo pipefail

DEST="${HOME}/.local/bin/entire-agent-shelley"
RECEIPT_DIR="${HOME}/.local/share/entire-agent-shelley"
RECEIPT="$RECEIPT_DIR/install.json"
REGISTRATIONS="${ENTIRE_SHELLEY_HOOK_STATE:-${HOME}/.config/entire/shelley-hooks}/registrations.json"
FORCE=0

if [[ ${1:-} == "--force" ]]; then
  FORCE=1
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--force]" >&2
  exit 2
fi

if [[ -f "$REGISTRATIONS" ]]; then
  count=$(python3 - "$REGISTRATIONS" <<'PY'
import json,sys
try:
    repos=json.load(open(sys.argv[1])).get("repositories",[])
    print(len(repos) if isinstance(repos,list) else 1)
except Exception:
    print(1)
PY
)
  if [[ $count -gt 0 ]]; then
    echo "refusing to uninstall: $count repository registration(s) remain" >&2
    echo "disable/unregister Shelley capture in every repository first" >&2
    exit 1
  fi
fi

if [[ ! -e "$DEST" ]]; then
  echo "entire-agent-shelley is not installed at $DEST"
  exit 0
fi

if [[ ! -f "$RECEIPT" && $FORCE -ne 1 ]]; then
  echo "missing installation receipt: $RECEIPT" >&2
  echo "refusing to remove an unverified executable; use --force if intentional" >&2
  exit 1
fi

if [[ -f "$RECEIPT" ]]; then
  recorded=$(python3 - "$RECEIPT" <<'PY'
import json,sys
try:
    print(json.load(open(sys.argv[1]))["sha256"])
except Exception:
    print("")
PY
)
  actual=$(sha256sum "$DEST" | awk '{print $1}')
  if [[ -z "$recorded" || "$recorded" != "$actual" ]]; then
    if [[ $FORCE -ne 1 ]]; then
      echo "installed executable differs from its receipt; refusing removal" >&2
      echo "use --force only after inspecting $DEST" >&2
      exit 1
    fi
  fi
fi

rm -f "$DEST" "$RECEIPT"
rmdir "$RECEIPT_DIR" 2>/dev/null || true
echo "removed $DEST"
