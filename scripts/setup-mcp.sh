#!/usr/bin/env bash
#
# setup-mcp.sh — register the five MCP servers the /fra and /zao commands depend on,
# as PLAIN (non-plugin) Claude Code MCP servers in USER scope.
#
# Why plain / user-scope? The command files reference tools by their plain names
# (mcp__lakar__*, mcp__pal__*, mcp__context7__*, mcp__tavily__*, mcp__notetask__*).
# A plugin-bundled MCP server would be renamed to mcp__plugin_<plugin>_<server>__*,
# which would silently break every command. So the servers must be registered with
# these exact keys, outside any plugin. User scope makes them available in every repo.
#
# Secrets: read from the environment (or a local .env you create from .env.example).
# Nothing secret is written into the repo — keys land only in your local ~/.claude.json.
#
# Usage:
#   cp .env.example .env && edit .env        # fill in your keys
#   ./scripts/setup-mcp.sh                    # auto-sources ./.env if present
#
set -euo pipefail

# ---- Locate repo + optional .env -------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ -f "$REPO_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  set -a; source "$REPO_DIR/.env"; set +a
  echo "Loaded keys from $REPO_DIR/.env"
fi

# ---- Config ----------------------------------------------------------------------
# Where to clone/build the Lakar MCP server. Override by exporting LAKAR_PM_DIR.
LAKAR_PM_DIR="${LAKAR_PM_DIR:-$HOME/lakar-pm}"
LAKAR_DIST="$LAKAR_PM_DIR/mcp-server/dist/index.js"
SCOPE="${MCP_SCOPE:-user}"   # user | project | local

# ---- Helpers ---------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

require_cmd() {
  if ! have "$1"; then
    echo "  ✗ prerequisite '$1' not found on PATH — $2" >&2
    return 1
  fi
}

# Re-register idempotently: drop any existing server of this name first.
add_server() {
  local name="$1"; shift
  claude mcp remove "$name" --scope "$SCOPE" >/dev/null 2>&1 || true
  if claude mcp add "$name" --scope "$SCOPE" "$@"; then
    echo "  ✓ registered '$name' (scope: $SCOPE)"
  else
    echo "  ✗ failed to register '$name'" >&2
    return 1
  fi
}

echo "==> fra/zao MCP setup"
require_cmd claude "install Claude Code first" || exit 1

# ---- 1. lakar (stdio, node) ------------------------------------------------------
echo "[1/5] lakar"
if [[ -z "${LAKAR_API_KEY:-}" ]]; then
  echo "  ! LAKAR_API_KEY not set — skipping lakar. Set it in .env to enable task tracking." >&2
else
  if [[ ! -f "$LAKAR_DIST" ]]; then
    echo "  · building Lakar MCP server in $LAKAR_PM_DIR ..."
    require_cmd git "needed to clone the Lakar server" || exit 1
    require_cmd node "needed to build/run the Lakar server" || exit 1
    if [[ ! -d "$LAKAR_PM_DIR/.git" ]]; then
      git clone https://github.com/zaidlakar/lakar-pm.git "$LAKAR_PM_DIR"
    fi
    ( cd "$LAKAR_PM_DIR/mcp-server" && npm install --ignore-scripts && npm run build )
  fi
  add_server lakar -e LAKAR_API_KEY="$LAKAR_API_KEY" -- node "$LAKAR_DIST"
fi

# ---- 2. pal (uvx, OpenRouter) ----------------------------------------------------
echo "[2/5] pal"
if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
  echo "  ! OPENROUTER_API_KEY not set — skipping pal (planner/debug). Set it in .env to enable." >&2
elif require_cmd uvx "install Astral uv (https://docs.astral.sh/uv/) for pal"; then
  add_server pal -e OPENROUTER_API_KEY="$OPENROUTER_API_KEY" -- \
    uvx --from git+https://github.com/BeehiveInnovations/pal-mcp-server.git pal-mcp-server
fi

# ---- 3. context7 (npx, optional key) ---------------------------------------------
echo "[3/5] context7"
if require_cmd npx "install Node.js for context7 + tavily"; then
  if [[ -n "${CONTEXT7_API_KEY:-}" ]]; then
    add_server context7 -e CONTEXT7_API_KEY="$CONTEXT7_API_KEY" -- npx -y @upstash/context7-mcp@latest
  else
    echo "  · CONTEXT7_API_KEY not set — registering without a key (lower rate limits)."
    add_server context7 -- npx -y @upstash/context7-mcp@latest
  fi
fi

# ---- 4. tavily (npx, key required) -----------------------------------------------
echo "[4/5] tavily"
if [[ -z "${TAVILY_API_KEY:-}" ]]; then
  echo "  ! TAVILY_API_KEY not set — skipping tavily (web search). Set it in .env to enable." >&2
elif require_cmd npx "install Node.js for tavily + context7"; then
  add_server tavily -e TAVILY_API_KEY="$TAVILY_API_KEY" -- npx -y tavily-mcp@latest
fi

# ---- 5. notetask (http, bearer) --------------------------------------------------
echo "[5/5] notetask"
if [[ -z "${NOTETASK_API_KEY:-}" ]]; then
  echo "  ! NOTETASK_API_KEY not set — skipping notetask. Set it in .env to enable Note&Task PM." >&2
else
  add_server notetask --transport http https://note-task-mcp.genesis-apps.com/mcp \
    --header "Authorization: Bearer $NOTETASK_API_KEY"
fi

echo
echo "==> Done. Verify with:  claude mcp list"
echo "    Tools will resolve as mcp__lakar__*, mcp__pal__*, mcp__context7__*, mcp__tavily__*, mcp__notetask__*"
