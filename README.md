# fra / zao workflow

The `/fra` (project setup) and `/zao` (task development) Claude Code workflow, packaged as two installable plugins distributed from one local marketplace.

- **`fra`** — set up a project: scaffold the repo, write PRD / brand / testing docs, and build out a Lakar project structure. → `/fra:*`
- **`zao`** — work a task end to end: begin → implement → test → submit (PR) → finish, plus fix / adjust / pause / resume. → `/zao:*`

The two are kept as **separate plugins** on purpose: a Claude Code plugin uses its own name as the (single) command namespace, so one combined plugin would rename every command to `/fra-zao-workflow:*`. Two plugins named `fra` and `zao` preserve the exact `/fra:` and `/zao:` prefixes the commands reference internally.

## Layout

```
fra-zao-workflow/
├── .claude-plugin/
│   └── marketplace.json        # lists both plugins (local sources)
├── plugins/
│   ├── fra/
│   │   ├── .claude-plugin/plugin.json
│   │   └── commands/           # /fra:brand, /fra:init, /fra:lakar, …
│   └── zao/
│       ├── .claude-plugin/plugin.json
│       └── commands/           # /zao:begin-task, /zao:workflow, …
├── scripts/
│   └── setup-mcp.sh            # registers the 5 MCP servers the commands need
├── .env.example               # the API keys setup-mcp.sh reads
└── README.md
```

## Install

### 1. Install the plugins

From a Claude Code session (use the absolute path to this directory):

```
/plugin marketplace add /home/himothy/project-007/fra-zao-workflow
/plugin install fra@fra-zao-workflow
/plugin install zao@fra-zao-workflow
```

For local development you can instead launch with `claude --plugin-dir /home/himothy/project-007/fra-zao-workflow/plugins/fra --plugin-dir .../zao`.

### 2. Wire up the MCP servers

The commands call tools on five MCP servers by their **plain** names — `mcp__lakar__*`, `mcp__pal__*`, `mcp__serena__*`, `mcp__context7__*`, `mcp__tavily__*`. These are **not** bundled in the plugins (a plugin-bundled server would be renamed `mcp__plugin_<plugin>_<server>__*` and silently break the commands). Register them with the setup script:

```bash
cp .env.example .env
$EDITOR .env                  # fill in your keys
./scripts/setup-mcp.sh        # registers all five in user scope
claude mcp list               # verify
```

| Server | Transport | Key needed | Used by |
|---|---|---|---|
| `lakar` | stdio (node) | `LAKAR_API_KEY` *(required)* | task tracking — most `/fra` and `/zao` commands |
| `pal` | uvx | `OPENROUTER_API_KEY` *(required)* | `planner` (`/zao:begin-task`, `/fra:lakar`), `debug` (`/zao:fix-issue`) |
| `serena` | uvx | none | semantic code editing (`/zao:adjust-feature`, `/zao:fix-issue`) |
| `context7` | npx | `CONTEXT7_API_KEY` *(optional)* | library docs lookup |
| `tavily` | npx | `TAVILY_API_KEY` *(required)* | web search |

Prerequisites: **Node.js** (lakar, context7, tavily), **[uv/uvx](https://docs.astral.sh/uv/)** (pal, serena), **git**. The script clones and builds the Lakar server (`github.com/zaidlakar/lakar-pm`) into `$HOME/lakar-pm` on first run; override with `LAKAR_PM_DIR`.

Secrets live only in your local `.env` (gitignored) and your local `~/.claude.json` — nothing secret is committed.

## Commands

**`/fra` — project setup**

| Command | Purpose |
|---|---|
| `/fra:init` | Scaffold a new repo (git + GitHub + config + CLAUDE.md) |
| `/fra:config` | Generate/update `.claude/project.yaml` for an existing project |
| `/fra:status` | Show setup progress and what's missing |
| `/fra:prd` · `/fra:update-prd` | Define / revise the PRD |
| `/fra:brand` · `/fra:update-brand` | Define / revise the brand & UX guide |
| `/fra:testing` · `/fra:update-testing` | Define / revise the testing strategy |
| `/fra:lakar` | Build the Lakar phase/milestone/task structure from the docs |
| `/fra:save` | Commit and push |

**`/zao` — task development**

| Command | Purpose |
|---|---|
| `/zao:workflow` | Explain the workflow and show where you are |
| `/zao:begin-task TSK-XXX` | Fetch the task, plan it, branch |
| `/zao:implement-task` | Execute the approved plan |
| `/zao:fix-issue <desc>` · `/zao:adjust-feature <desc>` | Fix a bug / make a tweak |
| `/zao:test-task` | Run checks |
| `/zao:submit-task` | Open a PR, set Lakar to In Review |
| `/zao:finish-task` | Merge, clean up, mark Done |
| `/zao:check-status` · `/zao:pause-task` · `/zao:resume-task` · `/zao:cancel-task` · `/zao:save` | Status & state helpers |

## Notes

- **No `/tre:` namespace.** Earlier drafts of `/fra:init` generated a `CLAUDE.md` referencing a fast-path `/tre:*` command set that never existed; those references have been removed from `init.md` and `lakar.md`. If you ever build main-branch/no-PR fast-path commands, add them as a third `tre` plugin the same way the `fra`/`zao` plugins are structured.
- **Serena / Context7 duplication.** If you already have Serena or Context7 installed as *marketplace plugins*, they expose tools under `mcp__plugin_serena_serena__*` / `mcp__plugin_context7_context7__*`. The commands need the plain `mcp__serena__*` / `mcp__context7__*` names this script registers. Both can coexist; remove the marketplace versions if you want to avoid duplicate tools.
- This directory is the marketplace root. To distribute it, push it to a Git repo and `/plugin marketplace add <repo-url>` instead of the local path.
