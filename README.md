# fra / zao workflow

The `/fra` (project setup) and `/zao` (task development) Claude Code workflow, packaged as two installable plugins distributed from one local marketplace.

- **`fra`** — set up a project: scaffold the repo, write PRD / brand / testing docs, and build out a project-management structure in Lakar, Note&Task or Cairn. → `/fra:*`
- **`zao`** — work a task end to end: begin → implement → test → submit (PR) → finish, plus fix / adjust / pause / resume, and (with Cairn) run a whole milestone autonomously with `/zao:run-milestone`. → `/zao:*`

The two are kept as **separate plugins** on purpose: a Claude Code plugin uses its own name as the (single) command namespace, so one combined plugin would rename every command to `/fra-zao-workflow:*`. Two plugins named `fra` and `zao` preserve the exact `/fra:` and `/zao:` prefixes the commands reference internally.

## Layout

```
fra-zao-workflow/
├── .claude-plugin/
│   └── marketplace.json        # lists both plugins (local sources)
├── plugins/
│   ├── fra/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/           # /fra:brand, /fra:init, /fra:setup-pm, …
│   │   └── reference/
│   │       └── pm-mapping.md   # byte-identical copy of the zao skill's mapping
│   └── zao/
│       ├── .claude-plugin/plugin.json
│       ├── commands/           # /zao:begin-task, /zao:workflow, /zao:run-milestone, …
│       ├── agents/
│       │   └── task-runner.md  # zao:task-runner, one milestone-run task per fresh context
│       └── skills/
│           └── pm-provider/    # zao:pm-provider: the provider rule + pm-mapping.md
├── scripts/
│   └── setup-mcp.sh            # registers the 6 MCP servers the commands need
├── .github/workflows/          # checks the two pm-mapping.md copies stay identical
├── .env.example               # the API keys (and Cairn URL) setup-mcp.sh reads
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

The commands call tools on six MCP servers by their **plain** names — `mcp__lakar__*`, `mcp__pal__*`, `mcp__context7__*`, `mcp__tavily__*`, `mcp__notetask__*`, `mcp__cairn__*`. These are **not** bundled in the plugins (a plugin-bundled server would be renamed `mcp__plugin_<plugin>_<server>__*` and silently break the commands). They're registered from a local clone of this repo with the setup script:

```bash
git clone https://github.com/zaidfrazao/fra-zao-workflow.git
cd fra-zao-workflow
cp .env.example .env
$EDITOR .env                  # fill in your keys
./scripts/setup-mcp.sh        # registers all six in user scope
claude mcp list               # verify
```

| Server | Transport | Key needed | Used by |
|---|---|---|---|
| `lakar` | stdio (node) | `LAKAR_API_KEY` *(required)* | task tracking — most `/fra` and `/zao` commands |
| `pal` | uvx | `OPENROUTER_API_KEY` *(required)* | `planner` (`/zao:begin-task`, `/fra:setup-pm`), `debug` (`/zao:fix-issue`) |
| `context7` | npx | `CONTEXT7_API_KEY` *(optional)* | library docs lookup |
| `tavily` | npx | `TAVILY_API_KEY` *(required)* | web search |
| `notetask` | http (bearer) | `NOTETASK_API_KEY` *(optional)* | task tracking for projects flagged `provider: notetask` |
| `cairn` | http (`headersHelper`) | `CAIRN_URL` *(optional)*; the token lives in the OS keychain | task tracking for projects flagged `provider: cairn`, and `/zao:run-milestone` |

`/zao:test-task` and the milestone E2E fallback also use the official **Playwright** Claude Code plugin (tools `mcp__plugin_playwright_playwright__*`). Install it with `/plugin`; the setup script warns when it is missing.

Prerequisites: **Node.js** (lakar, context7, tavily), **[uv/uvx](https://docs.astral.sh/uv/)** (pal), **git**. The script clones and builds the Lakar server (`github.com/zaidlakar/lakar-pm`) into `$HOME/lakar-pm` on first run; override with `LAKAR_PM_DIR`.

Secrets live only in your local `.env` (gitignored) and your local `~/.claude.json` — nothing secret is committed.

### 3. Connect Cairn (optional)

Cairn is the third PM provider, a personal PM suite with an MCP server, and the only one that supports milestone mode. Its token never goes in `.env` or `~/.claude.json`:

1. Set `CAIRN_URL` in `.env` to your Cairn instance (e.g. `https://cairn.example.com`).
2. In Cairn, open **Settings → Tokens** and create a token with the **Claude Code (full)** preset (`tasks:read`, `tasks:write`, `runs:write`).
3. Store it in the OS keychain (each command prompts for the token):
   ```bash
   security add-generic-password -s cairn -a "$USER" -w     # macOS
   secret-tool store --label=Cairn service cairn             # Linux (libsecret)
   ```
4. Run `./scripts/setup-mcp.sh`. It installs `~/.claude/cairn-headers.sh` (mode 700), which prints the `Authorization` header from the keychain, and `~/.claude/cairn-fetch.sh` (downloads Cairn attachments with the same token), then registers a user-scope server named `cairn`:
   ```bash
   claude mcp add-json --scope user cairn \
     '{"type":"http","url":"https://cairn.example.com/api/mcp","timeout":120000,"headersHelper":"$HOME/.claude/cairn-headers.sh"}'
   ```
   Claude Code runs the helper at each connection (and again after a 401), so the token is never in the environment that test suites, package scripts and dev servers inherit.
5. Verify with `claude mcp get cairn`, then `/mcp` inside Claude Code should list `cairn` with 38 tools.

**No keychain?** On a machine without `security` or `secret-tool`, the script registers the `headers` form with a literal `${CAIRN_TOKEN}` instead (single-quoted, so the secret never lands in `~/.claude.json`); export `CAIRN_TOKEN` in the shell that starts Claude Code. With this fallback, `/zao:run-milestone` and its task runner run repo commands with `env -u CAIRN_TOKEN`.

**Tokens for unattended runs.** For headless or unattended milestone runs (`claude -p "/zao:run-milestone QAA-M3"`), create a separate **Milestone runner** token in Cairn, limited to one workspace and at most 30 days, so a leaked runner token reaches one workspace for a short time. Headless runs need Claude Code 2.1.292 or later.

**Permissions for unattended runs (optional, add it yourself).** To let `/zao:run-milestone` work without stopping at Cairn permission prompts, you can add `"mcp__cairn__*"` to `permissions.allow` in your own `~/.claude/settings.json`. A narrower option is `"mcp__cairn__get_*"` and `"mcp__cairn__list_*"` (reads only). No script, command or agent in this repo writes permission rules or settings for you. Gate decisions still need you, in Cairn or in chat with the code the gate shows, whatever the permission rules say.

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
| `/fra:setup-pm` | Build the phase/milestone/task structure (Lakar, Note&Task or Cairn) |
| `/fra:save` | Commit and push |

**`/zao` — task development**

| Command | Purpose |
|---|---|
| `/zao:workflow` | Explain the workflow and show where you are |
| `/zao:begin-task TSK-XXX` | Fetch the task, plan it, branch (Cairn: `--reopen`, `--replan "<note>"`) |
| `/zao:implement-task` | Execute the approved plan |
| `/zao:fix-issue <desc>` · `/zao:adjust-feature <desc>` | Fix a bug / make a tweak |
| `/zao:test-task` | Run checks (`--profile quick\|standard\|full`; Cairn records the results) |
| `/zao:submit-task` | Open a PR, set the task to In Review |
| `/zao:finish-task` | Merge, clean up, mark Done |
| `/zao:check-status` · `/zao:pause-task` · `/zao:resume-task` · `/zao:cancel-task` · `/zao:save` | Status & state helpers |
| `/zao:run-milestone <milestone>` | **Cairn only.** Run every task of a milestone autonomously, then the full suite with E2E, then merge (see below) |

## Milestone mode (`/zao:run-milestone`, Cairn only)

`/zao:run-milestone QAA-M3` works through a whole Cairn milestone with the same per-task lifecycle, without stopping except at the gates you choose:

1. **Preflight** checks the provider, the Cairn token's scopes, a clean tree on the dev branch, `gh` auth and the `origin` remote, that every check has a command (an `e2e` command is required), and that the repo's merge rules allow the final merge.
2. **Dry run**: Cairn validates the milestone and freezes the task queue in dependency order. `--dry-run` stops here and prints the queue, errors and warnings.
3. A **milestone branch** (`milestone/QAA-M3-R2-rules-editor`) is cut from the dev branch (`git.default_branch`).
4. **Each task** runs in a fresh `zao:task-runner` subagent: `/zao:begin-task` → `/zao:implement-task` → `/zao:test-task --profile quick` (lint, typecheck, unit only) → `/zao:fix-issue` loop → `/zao:submit-task` → `/zao:finish-task`, all with `--autonomous`. Task branches are cut from the milestone branch and their PRs merge back into it, never into the dev branch.
5. **Verify**: once the queue is drained, the **full suite including E2E** runs once on the milestone branch (after merging in any new dev-branch commits). Failures become fix tasks that go through the same per-task flow, then the suite runs again.
6. **Finalize**: the milestone PR merges into the dev branch with `gh pr merge --match-head-commit`, only if the exact head that passed the full suite still contains the dev branch's tip. Tasks become Done only then.

Gates (approve the run plan, a task that ran out of fix attempts, a verify failure with no rounds left, the final merge, safety and precommit findings) are answered in Cairn (web or phone) or, for most kinds, in chat with the 6-digit code shown on the gate. A background watcher wakes the session when you decide in Cairn. Other forms: `--resume [<ref>]`, `--status [<ref>]`, `--pause`, `--cancel "<reason>"`.

The policy lives in `.claude/project.yaml` under `milestone_mode:` (written by `/fra:config` and `/fra:init`; every key is optional). Recommended: have your repo's PR CI filter on `pull_request: branches: [<dev branch>, main]`, so task PRs into `milestone/**` don't run the full CI.

## Notes

- **No `/tre:` namespace.** Earlier drafts of `/fra:init` generated a `CLAUDE.md` referencing a fast-path `/tre:*` command set that never existed; those references have been removed from `init.md` and `lakar.md`. If you ever build main-branch/no-PR fast-path commands, add them as a third `tre` plugin the same way the `fra`/`zao` plugins are structured.
- **Context7 duplication.** If you already have Context7 installed as a *marketplace plugin*, it exposes tools under `mcp__plugin_context7_context7__*`. The commands need the plain `mcp__context7__*` name this script registers. Both can coexist; remove the marketplace version if you want to avoid duplicate tools.
- This directory is the marketplace root. To distribute it, push it to a Git repo and `/plugin marketplace add <repo-url>` instead of the local path.
- **Choosing a PM backend per project.** Set `project_management.provider` to `lakar` (default),
  `notetask` or `cairn` in `.claude/project.yaml`. Projects with no `project_management` block
  fall back to Lakar, so existing projects are unaffected. `/fra:config` migrates a legacy
  `lakar:` config. The resolution rule lives in one place, the `zao:pm-provider` skill
  (`plugins/zao/skills/pm-provider/SKILL.md`), which every PM-touching command invokes; the
  `fra` commands use it too, so install both plugins. For Cairn set `workspace` and
  `project_identifier` and omit `statuses:` (Cairn's statuses are fixed; paused and blocked are
  flags).
- **`/fra:lakar` is deprecated** in favor of `/fra:setup-pm` (provider-aware). The old name
  still works as an alias.
- **Mapping doc must stay in sync.** `plugins/zao/skills/pm-provider/pm-mapping.md` (read at
  runtime by the skill) and `plugins/fra/reference/pm-mapping.md` are byte-identical copies —
  edit both. Verify with:
  `cmp plugins/zao/skills/pm-provider/pm-mapping.md plugins/fra/reference/pm-mapping.md`
  (CI runs the same check).
