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
│   │   └── commands/           # /fra:brand, /fra:init, /fra:setup-pm, …
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

From a Claude Code session, add this repo as a marketplace and install both plugins:

```
/plugin marketplace add zaidfrazao/fra-zao-workflow
/plugin install fra@fra-zao-workflow
/plugin install zao@fra-zao-workflow
```

`/plugin marketplace add` also accepts a full Git URL (`https://github.com/zaidfrazao/fra-zao-workflow.git`) or, if you've cloned the repo, the absolute path to your local checkout. For local development you can instead launch with `claude --plugin-dir <repo>/plugins/fra --plugin-dir <repo>/plugins/zao`.

### 2. Wire up the MCP servers

The commands call tools on five MCP servers by their **plain** names — `mcp__lakar__*`, `mcp__pal__*`, `mcp__context7__*`, `mcp__tavily__*`, `mcp__notetask__*`. These are **not** bundled in the plugins (a plugin-bundled server would be renamed `mcp__plugin_<plugin>_<server>__*` and silently break the commands). They're registered from a local clone of this repo with the setup script:

```bash
git clone https://github.com/zaidfrazao/fra-zao-workflow.git
cd fra-zao-workflow
cp .env.example .env
$EDITOR .env                  # fill in your keys
./scripts/setup-mcp.sh        # registers all five in user scope
claude mcp list               # verify
```

| Server | Transport | Key needed | Used by |
|---|---|---|---|
| `lakar` | stdio (node) | `LAKAR_API_KEY` *(required)* | task tracking — most `/fra` and `/zao` commands |
| `pal` | uvx | `OPENROUTER_API_KEY` *(required)* | `planner` (`/zao:begin-task`, `/fra:setup-pm`), `debug` (`/zao:fix-issue`) |
| `context7` | npx | `CONTEXT7_API_KEY` *(optional)* | library docs lookup |
| `tavily` | npx | `TAVILY_API_KEY` *(required)* | web search |
| `notetask` | http (bearer) | `NOTETASK_API_KEY` *(optional)* | task tracking for projects flagged `provider: notetask` |

Prerequisites: **Node.js** (lakar, context7, tavily), **[uv/uvx](https://docs.astral.sh/uv/)** (pal), **git**. The script clones and builds the Lakar server (`github.com/zaidlakar/lakar-pm`) into `$HOME/lakar-pm` on first run; override with `LAKAR_PM_DIR`.

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
| `/fra:setup-pm` | Build the phase/milestone/task structure (Lakar or Note&Task) |
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
- **Context7 duplication.** If you already have Context7 installed as a *marketplace plugin*, it exposes tools under `mcp__plugin_context7_context7__*`. The commands need the plain `mcp__context7__*` name this script registers. Both can coexist; remove the marketplace version if you want to avoid duplicate tools.
- This directory is the marketplace root. To distribute it, push it to a Git repo and `/plugin marketplace add <repo-url>` instead of the local path.
- **Choosing a PM backend per project.** Set `project_management.provider` to `lakar` (default)
  or `notetask` in `.claude/project.yaml`. Projects with no `project_management` block fall back
  to Lakar, so existing projects are unaffected. `/fra:config` migrates a legacy `lakar:` config.
- **`/fra:lakar` is deprecated** in favor of `/fra:setup-pm` (provider-aware). The old name
  still works as an alias.
- **Mapping doc must stay in sync.** `plugins/fra/reference/pm-mapping.md` and
  `plugins/zao/reference/pm-mapping.md` are byte-identical copies — edit both. Verify with:
  `diff plugins/fra/reference/pm-mapping.md plugins/zao/reference/pm-mapping.md`.
