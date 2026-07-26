#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
SOURCE="$ROOT/entire-agent-shelley"
VERSION=$(tr -d '[:space:]' <"$ROOT/VERSION")
DEST_DIR="${HOME}/.local/bin"
DEST="$DEST_DIR/entire-agent-shelley"
RECEIPT_DIR="${HOME}/.local/share/entire-agent-shelley"
RECEIPT="$RECEIPT_DIR/install.json"
FORCE=0

if [[ ${1:-} == "--force" ]]; then
  FORCE=1
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--force]" >&2
  exit 2
fi

[[ -x "$SOURCE" ]] || { echo "missing executable: $SOURCE" >&2; exit 1; }
mkdir -p "$DEST_DIR" "$RECEIPT_DIR"
chmod 700 "$RECEIPT_DIR"

owned=0
if [[ -f "$DEST" && -f "$RECEIPT" ]]; then
  recorded=$(python3 - "$RECEIPT" <<'PY'
import json,sys
try:
    print(json.load(open(sys.argv[1]))["sha256"])
except Exception:
    print("")
PY
)
  actual=$(sha256sum "$DEST" | awk '{print $1}')
  [[ -n "$recorded" && "$recorded" == "$actual" ]] && owned=1
fi

if [[ -e "$DEST" && $owned -eq 0 ]] && ! cmp -s "$SOURCE" "$DEST" && [[ $FORCE -ne 1 ]]; then
  echo "refusing to overwrite unrelated executable: $DEST" >&2
  echo "inspect it, then rerun with --force if replacement is intentional" >&2
  exit 1
fi

tmp=$(mktemp "$DEST_DIR/.entire-agent-shelley.XXXXXX")
trap 'rm -f "$tmp"' EXIT
install -m 0755 "$SOURCE" "$tmp"
mv -f "$tmp" "$DEST"
trap - EXIT
sha=$(sha256sum "$DEST" | awk '{print $1}')
python3 - "$RECEIPT" "$VERSION" "$DEST" "$sha" <<'PY'
import json,sys
path,version,destination,sha=sys.argv[1:]
with open(path,"w") as f:
    json.dump({"name":"entire-agent-shelley","version":version,"destination":destination,"sha256":sha},f,indent=2)
    f.write("\n")
PY
chmod 600 "$RECEIPT"
printf 'installed entire-agent-shelley %s to %s\n' "$VERSION" "$DEST"
printf 'sha256 %s\n' "$sha"
