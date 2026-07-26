#!/bin/bash
set -euo pipefail

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

ADAPTER=$(cd "$(dirname "$0")" && pwd)/entire-agent-shelley
REAL_ENTIRE=$(command -v entire || true)
TEST_HOME="$ROOT/home"
REPO="$ROOT/repo"
DB="$TEST_HOME/.config/shelley/shelley.db"
HOOKS="$TEST_HOME/.config/shelley/hooks"
STATE="$TEST_HOME/.config/entire/shelley-hooks"
CACHE="$TEST_HOME/.cache/entire-agent-shelley"
BIN="$TEST_HOME/.local/bin"
mkdir -p "$BIN" "$HOOKS" "$(dirname "$DB")"
ln -s "$ADAPTER" "$BIN/entire-agent-shelley"

export HOME="$TEST_HOME"
if [[ -n "$REAL_ENTIRE" ]]; then
  export PATH="$BIN:$(dirname "$REAL_ENTIRE"):/usr/bin:/bin"
else
  export PATH="$BIN:/usr/bin:/bin"
fi
export SHELLEY_DB="$DB"
export SHELLEY_HOOKS_DIR="$HOOKS"
export ENTIRE_SHELLEY_HOOK_STATE="$STATE"
export ENTIRE_SHELLEY_CACHE="$CACHE"
unset SHELLEY_CWD SHELLEY_GIT_ROOT SHELLEY_CONVERSATION_ID ENTIRE_REPO_ROOT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_jq() {
  local input=$1 expression=$2
  jq -e "$expression" <<<"$input" >/dev/null || fail "jq assertion failed: $expression in $input"
}

# Protocol declaration and lifecycle parsing.
INFO=$(ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" info)
assert_jq "$INFO" '.name == "shelley" and .capabilities.hooks == true'
assert_jq "$INFO" '(.hook_names | sort) == (["initial-turn-start","session-start","turn-end","turn-start"] | sort)'

mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name Test
printf 'base\n' >"$REPO/file.txt"
git -C "$REPO" add file.txt
git -C "$REPO" commit -qm base
mkdir -p "$REPO/.entire"
printf '%s\n' '{"enabled":true,"telemetry":false,"external_agents":true,"checkpoints":{"primary":{"type":"git-branch"}}}' >"$REPO/.entire/settings.json"

python3 - "$DB" "$REPO" <<'PY'
import sqlite3
import sys

path, repo = sys.argv[1:]
conn = sqlite3.connect(path)
conn.executescript(
    """
    CREATE TABLE conversations(
      conversation_id TEXT PRIMARY KEY, slug TEXT, cwd TEXT, model TEXT,
      parent_conversation_id TEXT, created_at TEXT, updated_at TEXT
    );
    CREATE TABLE messages(
      message_id TEXT PRIMARY KEY, conversation_id TEXT, sequence_id INTEGER,
      type TEXT, llm_data TEXT, created_at TEXT, model_name TEXT,
      excluded_from_context INTEGER DEFAULT 0
    );
    """
)
conn.execute(
    "INSERT INTO conversations VALUES(?,?,?,?,?,?,?)",
    ("conv-live", "live", repo, "gpt-test", None,
     "2026-07-26 00:00:00", "2026-07-26 00:00:00"),
)
conn.commit()
PY

NEW_PAYLOAD=$(jq -nc --arg repo "$REPO" '{prompt:"edit file",model:"gpt-test",cwd:$repo,readonly:{conversation_id:"conv-live",is_subagent:false}}')
CHAT_PAYLOAD='{"message":"continue","readonly":{"conversation_id":"conv-live","model":"gpt-test","queued":false}}'
END_PAYLOAD='{"type":"end_of_turn","conversation_id":"conv-live","timestamp":"2026-07-26T00:02:00Z","model":"gpt-test","final_response":"done"}'

EVENT=$(printf '%s' "$NEW_PAYLOAD" | ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" parse-hook --hook session-start)
assert_jq "$EVENT" '.type == 1 and .session_id == "conv-live"'
EVENT=$(printf '%s' "$NEW_PAYLOAD" | ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" parse-hook --hook initial-turn-start)
assert_jq "$EVENT" '.type == 2 and .prompt == "edit file"'
EVENT=$(printf '%s' "$CHAT_PAYLOAD" | ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" parse-hook --hook turn-start)
assert_jq "$EVENT" '.type == 2 and .prompt == "continue"'

# Hook installation preserves and chains a pre-existing hook.
cat >"$ROOT/original-new-conversation" <<'EOF'
#!/bin/sh
printf '{"slug":"preserved"}'
EOF
chmod +x "$ROOT/original-new-conversation"
ln -s "$ROOT/original-new-conversation" "$HOOKS/new-conversation"

INSTALL=$(ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" install-hooks)
assert_jq "$INSTALL" '.hooks_installed == 3'
INSTALLED=$(ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" are-hooks-installed)
assert_jq "$INSTALLED" '.installed == true'
[[ -x "$HOOKS/new-conversation" && ! -L "$HOOKS/new-conversation" ]] || fail "managed new-conversation hook not installed"
cat >"$ROOT/fake-entire" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$ENTIRE_FAKE_ARGS"
cat >>"$ENTIRE_FAKE_INPUT"
printf '\n' >>"$ENTIRE_FAKE_INPUT"
EOF
chmod +x "$ROOT/fake-entire"
export ENTIRE_FAKE_ARGS="$ROOT/fake-args.log"
export ENTIRE_FAKE_INPUT="$ROOT/fake-input.log"
OUTPUT=$(printf '%s' "$NEW_PAYLOAD" | ENTIRE_BIN="$ROOT/fake-entire" "$HOOKS/new-conversation")
assert_jq "$OUTPUT" '.slug == "preserved"'
[[ $(wc -l <"$ENTIRE_FAKE_ARGS") -eq 2 ]] || fail "new conversation did not dispatch two Entire lifecycle events"
grep -q '"conversation_id":"conv-live"' "$ENTIRE_FAKE_INPUT" || fail "prior hook partial output dropped readonly identity"
grep -q '"cwd":"'"$REPO"'"' "$ENTIRE_FAKE_INPUT" || fail "prior hook partial output dropped repository cwd"
: >"$ENTIRE_FAKE_ARGS"
printf '%s' "$CHAT_PAYLOAD" | ENTIRE_BIN="$ROOT/fake-entire" "$HOOKS/chat-message" >/dev/null
[[ ! -s "$ENTIRE_FAKE_ARGS" ]] || fail "next TurnStart overtook the active TurnEnd"
printf '%s' "$END_PAYLOAD" | ENTIRE_BIN="$ROOT/fake-entire" "$HOOKS/end-of-turn" >/dev/null
mapfile -t ORDERED <"$ENTIRE_FAKE_ARGS"
[[ ${#ORDERED[@]} -eq 2 ]] || fail "deferred turn did not dispatch after TurnEnd"
[[ ${ORDERED[0]} == "hooks shelley turn-end" && ${ORDERED[1]} == "hooks shelley turn-start" ]] || fail "deferred lifecycle order is incorrect"
STABLE="$STATE/bin/entire-agent-shelley"
mv "$STABLE" "$STABLE.away"
OUTPUT=$(printf '%s' "$NEW_PAYLOAD" | "$HOOKS/new-conversation")
assert_jq "$OUTPUT" '.slug == "preserved"'
mv "$STABLE.away" "$STABLE"
cp "$STABLE" "$STABLE.good"
printf '#!/missing/interpreter\n' >"$STABLE"
chmod +x "$STABLE"
printf '%s' "$CHAT_PAYLOAD" | "$HOOKS/chat-message" >/dev/null 2>&1 || fail "adapter launch failure blocked Shelley"
mv "$STABLE.good" "$STABLE"
cp "$ROOT/original-new-conversation" "$ROOT/original-new-conversation.good"
printf '#!/bin/sh\nexit 7\n' >"$ROOT/original-new-conversation"
chmod +x "$ROOT/original-new-conversation"
set +e
printf '%s' "$NEW_PAYLOAD" | "$HOOKS/new-conversation" >/dev/null
PRIOR_RC=$?
set -e
[[ $PRIOR_RC -eq 7 ]] || fail "preserved hook failure status was not propagated"
mv "$ROOT/original-new-conversation.good" "$ROOT/original-new-conversation"
chmod +x "$ROOT/original-new-conversation"
cp "$ROOT/fake-entire" "$BIN/entire"
chmod +x "$BIN/entire"
: >"$ENTIRE_FAKE_ARGS"
OUTPUT=$(printf '%s' "$NEW_PAYLOAD" | PATH=/usr/bin:/bin "$HOOKS/new-conversation")
assert_jq "$OUTPUT" '.slug == "preserved"'
[[ $(wc -l <"$ENTIRE_FAKE_ARGS") -eq 2 ]] || fail "plugin did not find ~/.local/bin/entire outside Shelley PATH"
rm -f "$BIN/entire"
: >"$ENTIRE_FAKE_ARGS"
QUEUED='{"message":"later","readonly":{"conversation_id":"conv-live","model":"gpt-test","queued":true}}'
printf '%s' "$QUEUED" | ENTIRE_BIN="$ROOT/fake-entire" "$HOOKS/chat-message" >/dev/null
[[ ! -s "$ENTIRE_FAKE_ARGS" ]] || fail "queued chat message dispatched an out-of-order TurnStart"
INSTALL=$(ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" install-hooks)
assert_jq "$INSTALL" '.hooks_installed == 0'

# Full real-Entire lifecycle: live TurnEnd materializes Shelley SQLite directly,
# commit condensation adds a trailer, and the checkpoint ref carries transcript.
if [[ ${ENTIRE_SKIP_REAL:-0} == 1 ]]; then
  echo "SKIP: real Entire lifecycle integration"
else
  [[ -n "$REAL_ENTIRE" ]] || fail "Entire CLI is required unless ENTIRE_SKIP_REAL=1"
(
  cd "$REPO"
  entire enable --agent shelley --project --telemetry=false --checkpoint-backend branch >/dev/null
)
ln -sf "$REAL_ENTIRE" "$BIN/entire"
printf '%s' "$NEW_PAYLOAD" | PATH=/usr/bin:/bin "$HOOKS/new-conversation" >/dev/null
printf 'changed\n' >>"$REPO/file.txt"
python3 - "$DB" <<'PY'
import json
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
def body(text):
    return json.dumps({"Content": [{"Type": 2, "Text": text}]})
conn.execute(
    "INSERT INTO messages VALUES(?,?,?,?,?,?,?,0)",
    ("u1", "conv-live", 1, "user", body("edit file"),
     "2026-07-26 00:01:00", None),
)
conn.execute(
    "INSERT INTO messages VALUES(?,?,?,?,?,?,?,0)",
    ("a1", "conv-live", 2, "agent", body("done"),
     "2026-07-26 00:02:00", "gpt-test"),
)
conn.commit()
PY
printf '%s' "$END_PAYLOAD" | PATH=/usr/bin:/bin "$HOOKS/end-of-turn" >/dev/null

git -C "$REPO" add file.txt
git -C "$REPO" commit -qm live
COMMIT_BODY=$(git -C "$REPO" log -1 --format=%B)
grep -q '^Entire-Checkpoint: ' <<<"$COMMIT_BODY" || fail "commit lacks Entire checkpoint trailer"
git -C "$REPO" show-ref --verify --quiet refs/heads/entire/checkpoints/v1 || fail "checkpoint ref missing"
CHECKPOINT_TREE=$(git -C "$REPO" ls-tree -r --name-only entire/checkpoints/v1)
grep -q '/transcript.jsonl$' <<<"$CHECKPOINT_TREE" || fail "checkpoint transcript missing"
TRANSCRIPT_PATH=$(grep '/transcript.jsonl$' <<<"$CHECKPOINT_TREE" | head -1)
git -C "$REPO" show "entire/checkpoints/v1:$TRANSCRIPT_PATH" | grep -q '"text":"done"' || fail "direct Shelley transcript content missing"
fi

# Global Shelley hooks are reference-counted across Entire-enabled repositories.
REPO2="$ROOT/repo-two"
mkdir -p "$REPO2/.entire"
git -C "$REPO2" init -q
printf '%s\n' '{"enabled":true,"external_agents":true}' >"$REPO2/.entire/settings.json"
UNREGISTERED=$(jq -nc --arg repo "$REPO2" '{prompt:"other",model:"gpt",cwd:$repo,readonly:{conversation_id:"other-1",is_subagent:false}}')
: >"$ENTIRE_FAKE_ARGS"
printf '%s' "$UNREGISTERED" | ENTIRE_BIN="$ROOT/fake-entire" "$ADAPTER" run-hook --hook new-conversation >/dev/null
[[ ! -s "$ENTIRE_FAKE_ARGS" ]] || fail "unregistered repository dispatched live capture"
INSTALL=$(ENTIRE_REPO_ROOT="$REPO2" "$ADAPTER" install-hooks)
assert_jq "$INSTALL" '.hooks_installed == 0'
ENTIRE_REPO_ROOT="$REPO" "$ADAPTER" uninstall-hooks >/dev/null
[[ -x "$HOOKS/new-conversation" && ! -L "$HOOKS/new-conversation" ]] || fail "uninstalling one repository removed shared Shelley hooks"

# Removing the last repository restores the original symlink and removes only
# Entire-owned hooks.
ENTIRE_REPO_ROOT="$REPO2" "$ADAPTER" uninstall-hooks >/dev/null
[[ -L "$HOOKS/new-conversation" ]] || fail "original symlink was not restored"
[[ $(readlink "$HOOKS/new-conversation") == "$ROOT/original-new-conversation" ]] || fail "restored symlink target changed"
[[ ! -e "$HOOKS/chat-message" && ! -e "$HOOKS/end-of-turn" ]] || fail "new Entire hooks were not removed"

# Subagent new-conversation hooks are deliberately ignored by dispatch.
SUBAGENT=$(jq -nc --arg repo "$REPO" '{prompt:"child",model:"gpt",cwd:$repo,readonly:{conversation_id:"child-1",is_subagent:true}}')
mkdir -p "$ROOT/fake-bin"
cat >"$ROOT/fake-bin/entire" <<'EOF'
#!/bin/sh
echo called >>"$ENTIRE_FAKE_LOG"
EOF
chmod +x "$ROOT/fake-bin/entire"
export ENTIRE_FAKE_LOG="$ROOT/fake.log"
printf '%s' "$SUBAGENT" | ENTIRE_BIN="$ROOT/fake-bin/entire" "$ADAPTER" run-hook --hook new-conversation >/dev/null
[[ ! -e "$ENTIRE_FAKE_LOG" ]] || fail "subagent lifecycle was captured"

echo "PASS: direct Shelley live Entire plugin"
