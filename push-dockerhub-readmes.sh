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

for dir in "$SRC_DIR"/*/; do
  repo=$(basename "$dir")
  # README.md is canonical; DOCKERHUB.md kept only for not-yet-migrated images.
  if [ -r "$dir/DOCKERHUB.md" ]; then md="$dir/DOCKERHUB.md"
  elif [ -r "$dir/README.md" ]; then md="$dir/README.md"
  else continue; fi
  code=$(jq -Rs '{full_description: .}' "$md" | \
    curl -s -o /dev/null -w '%{http_code}' -X PATCH \
      -H "Authorization: JWT $TOKEN" -H "Content-Type: application/json" \
      -d @- "https://hub.docker.com/v2/repositories/$NS/$repo/")
  echo "$repo -> $code"
done
