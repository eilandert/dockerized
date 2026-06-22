#!/usr/bin/env bash
# Push every src/<img>/README.md (or legacy DOCKERHUB.md) to its Docker Hub
# repo long description.
# Docker Hub has no README-write MCP; this uses the v2 REST API.
#
# PAT (scope Read & Write) lives gitignored, NOT in this file:
#   /opt/packages/tools/.dockerhub-pat   (perms 0600)
# Generate at hub.docker.com -> Account Settings -> Personal access tokens.
set -euo pipefail

NS=eilandert
PAT_FILE=/opt/packages/tools/.dockerhub-pat
SRC_DIR="$(cd "$(dirname "$0")/src" && pwd)"

[ -r "$PAT_FILE" ] || { echo "missing $PAT_FILE" >&2; exit 1; }
PAT=$(tr -d '[:space:]' < "$PAT_FILE")

TOKEN=$(curl -s -H "Content-Type: application/json" \
  -d "{\"username\":\"$NS\",\"password\":\"$PAT\"}" \
  https://hub.docker.com/v2/users/login/ | jq -r '.token // empty')
[ -n "$TOKEN" ] || { echo "login failed (rotate PAT?)" >&2; exit 1; }

# Docker Hub caps full_description at 25000 BYTES (UTF-8); longer bodies 400.
LIMIT=25000

for dir in "$SRC_DIR"/*/; do
  repo=$(basename "$dir")
  # README.md is canonical; DOCKERHUB.md kept only for not-yet-migrated images.
  if [ -r "$dir/README.md" ]; then md="$dir/README.md"
  else continue; fi
  body=$(cat "$md")
  if [ "$(wc -c < "$md")" -gt "$LIMIT" ]; then
    gh="https://github.com/$NS/$repo"
    top=$'> ⚠️ **THIS README IS TOO LONG — Docker Hub caps descriptions at '"$LIMIT"$' bytes.**\n> **See the full README on GitHub: '"$gh"$'**\n\n---\n\n'
    bot=$'\n\n---\n\n> ⚠️ **TRUNCATED — see the full README on GitHub: '"$gh"$'**\n'
    bbytes=$(printf '%s%s' "$top" "$bot" | wc -c)
    # byte-budget the body (UTF-8), then cut to last line boundary so no
    # partial multibyte char survives. 64-byte margin for safety.
    budget=$((LIMIT - bbytes - 64))
    mid=$(head -c "$budget" "$md")
    mid=${mid%$'\n'*}
    body="$top$mid$bot"
    echo "$repo: README too long, truncated to $(printf '%s' "$body" | wc -c) bytes" >&2
  fi
  code=$(printf '%s' "$body" | jq -Rs '{full_description: .}' | \
    curl -s -o /dev/null -w '%{http_code}' -X PATCH \
      -H "Authorization: JWT $TOKEN" -H "Content-Type: application/json" \
      -d @- "https://hub.docker.com/v2/repositories/$NS/$repo/")
  echo "$repo -> $code"
done
