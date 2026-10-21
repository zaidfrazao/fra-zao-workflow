---
description: Initialize a new project with git, GitHub repo, and Claude Code configuration
allowed-tools: AskUserQuestion, Bash, Write, Read, Skill, mcp__notetask__list_workspaces, mcp__cairn__list_workspaces, mcp__cairn__list_projects, mcp__cairn__get_current_user
---

Initialize a new project with git repository, private GitHub repo, and Claude Code configuration.

## Steps

### Step 1: Gather Project Information

Use `AskUserQuestion` to ask the following (can be combined into one multi-question prompt):

1. "What is the name of your project?" (This will be used for the repo name)
2. "Give a brief one-line description of the project"
3. "What type of project is this?"
   - Options: Web App, API/Backend, CLI Tool, Library/Package, Desktop App, Mobile App, Fullstack
4. "Who will primarily be using Claude Code on this project?"
   - Options:
     - **Technical user** - Comfortable with code, git, and technical terminology
     - **Non-technical user** - Prefers simple explanations and guided workflows
5. "Which project-management app should this project use?"
   - Options:
     - **Lakar** (default) - the original backend
     - **Note&Task** - alternative PM app
     - **Cairn** - PM app with milestone runs (`/zao:run-milestone`)

Then, depending on the answer:

- **Lakar:** "What is your Lakar client name?" (optional, can be left blank)
- **Note&Task:** "What project identifier should tasks use? (1–6 uppercase letters/digits, e.g.
  NOTET)". Resolve the workspace with `mcp__notetask__list_workspaces`: if exactly one, use it
  silently; if several, ask which; store its name.
- **Cairn:** resolve the workspace with `mcp__cairn__list_workspaces {}`: if exactly one, use its
  slug silently; if several, ask which; store its **slug**. Then ask "What project identifier
  should tasks use? (1–6 capitals/digits starting with a letter, e.g. QAA)" (offer existing
  projects from `mcp__cairn__list_projects { workspace: <slug> }` if the user wants to reuse
  one). If the `mcp__cairn__*` tools are not available, say that the `cairn` MCP server is not
  registered yet (`scripts/setup-mcp.sh` in the fra-zao-workflow repo registers it), ask for the
  workspace slug directly, and continue.

The provider is always written explicitly into `.claude/project.yaml`.

### Step 2: Detect Build System

Check for existing build tools to auto-configure:

```bash
# Check for package managers and build tools
ls package.json 2>/dev/null && echo "DETECTED: npm/node"
ls Cargo.toml 2>/dev/null && echo "DETECTED: cargo/rust"
ls go.mod 2>/dev/null && echo "DETECTED: go"
ls Makefile 2>/dev/null && echo "DETECTED: make"
ls nx.json 2>/dev/null && echo "DETECTED: nx"
ls pnpm-lock.yaml 2>/dev/null && echo "DETECTED: pnpm"
ls yarn.lock 2>/dev/null && echo "DETECTED: yarn"
ls pyproject.toml setup.py requirements.txt 2>/dev/null && echo "DETECTED: python"
```

Set `{build_tool}` based on detection (default to "npm" for Node projects, prompt if unclear).

### Step 3: Verify Prerequisites

Check that we're in a suitable directory:
```bash
pwd
ls -la
```

If the directory already has a `.git` folder:
> "This directory is already a git repository. Would you like to continue anyway (this will connect it to a new GitHub repo) or stop?"

### Step 4: Initialize Git Repository

```bash
git init
```

### Step 5: Create GitHub Repository

Create a private GitHub repository:
```bash
gh repo create {project-name} --private --description "{description}" --source=. --remote=origin
```

If `gh` is not authenticated, guide the user:
> "GitHub CLI needs to be authenticated. Run `gh auth login` and follow the prompts, then run `/fra:init` again."

### Step 6: Create Directory Structure

```bash
mkdir -p docs
mkdir -p .claude/commands
```

### Step 7: Create Project Configuration

Create `.claude/project.yaml` with detected/selected values:

```yaml
# Claude Code Project Configuration

project:
  name: "{project-name}"
  description: "{description}"
  type: {project-type}  # web-app, api, cli, library, desktop-app, mobile-app, fullstack

user:
  mode: {user-mode}  # technical or non-technical

team:
  lead: ""  # Set this to the technical lead's name for review notifications

git:
  default_branch: main            # the dev branch; tasks (and milestone branches) start here
  branch_prefixes:
    feature: "feature/"
    bugfix: "fix/"
    hotfix: "hotfix/"
    chore: "chore/"
  merge_strategy: squash          # task PRs
  delete_branch_after_merge: true
  require_pr_approval: true       # /zao:finish-task waits for an approved review; also resolves
                                  # milestone_mode.gates.final_merge: auto (a missing key counts as true)

build:
  tool: {build_tool}
  commands:
    lint: "{auto-detected or default}"
    typecheck: "{auto-detected or default}"
    build: "{auto-detected or default}"
    test: "{auto-detected or default}"   # the "unit" check
    e2e: ""                             # end-to-end suite; milestone runs require it (unless allow_e2e_fallback)
    dev: "{auto-detected or default}"
  dev_port: 3000

project_management:
  provider: {provider}       # lakar | notetask | cairn  (always written explicitly)
  client: ""                 # lakar only — your Lakar client name
  project_identifier: ""     # notetask and cairn — e.g. NOTET, QAA
  workspace: ""              # notetask: workspace name; cairn: workspace slug, passed as-is
  statuses:                  # lakar and notetask only — OMIT this block for cairn
    todo: "Todo"
    in_progress: "In Progress"
    in_review: "In Review"
    done: "Done"
    paused: null
    blocked: null
    canceled: null

commits:
  types:
    feature: "feat"
    bugfix: "fix"
    refactor: "refactor"
    style: "style"
    docs: "docs"
    test: "test"
    chore: "chore"
  include_scope: false
  footer: |
    🤖 Generated with Claude Code

docs:
  brand_template: {full if UI project, minimal otherwise}
  testing_template: full
  design_reference: ""            # optional URL (e.g. a Figma file)

milestone_mode:                   # /zao:run-milestone (Cairn only); every key optional, defaults shown
  task_checks: [lint, typecheck, unit]             # quick checks per task (only those with a command)
  full_suite: [lint, typecheck, unit, build, e2e]  # run once at the end; always includes e2e
  on_task_failure: pause          # pause | continue_independent
  max_fix_attempts: 3             # 0-5 fix iterations per task attempt
  max_verify_fix_rounds: 2        # 0-3 failed full-suite rounds that may be fixed
  task_pr_ci: none                # none | required_only (task PRs into the milestone branch)
  allow_e2e_fallback: false       # true: drive TESTING_STRATEGY flows with the Playwright MCP when there is no e2e command
  trusted_authors: starter        # starter | admins | members: whose task edits a run accepts without a safety gate
  include_backlog: false          # also queue the milestone's backlog tasks
  require_acceptance_criteria: true
  lease_ttl_minutes: 15           # 5-60
  final_merge_strategy: merge     # merge | squash | rebase (must be allowed by the repo)
  sync_dev_before_verify: true    # merge new dev-branch commits in before the full suite
  gates: {run_plan: true, task_plan: false, checkpoint_every: 0, scope_expansion: false, final_merge: auto}
```

**Provider-specific values:**
- `provider: lakar` — keep the Lakar status names shown and fill `client` if given.
- `provider: notetask` — set `project_identifier` and `workspace`, and use the Note&Task phase
  values (`todo`, `in_progress`, `in_review`, `done`, `canceled`) under `statuses`.
- `provider: cairn` — set `workspace` (slug) and `project_identifier`, leave `client` out, and
  **omit the whole `statuses:` block**, writing `# statuses: omit for cairn (fixed enum;
  paused/blocked are flags)` in its place.

The `milestone_mode:` block is written for every provider, but only `/zao:run-milestone` with
`provider: cairn` reads it. Keep only the `task_checks` and `full_suite` names that have a command
(`unit` maps to `build.commands.test`); `e2e` stays in `full_suite`, so a milestone run needs
`build.commands.e2e` (fill it in once the E2E suite exists) or `allow_e2e_fallback: true`.

**Build command defaults by tool:**
- **npm**: `npm run lint`, `npm run typecheck`, `npm run build`, `npm run test`, `npm run dev`
- **yarn**: `yarn lint`, `yarn typecheck`, `yarn build`, `yarn test`, `yarn dev`
- **pnpm**: `pnpm lint`, `pnpm typecheck`, `pnpm build`, `pnpm test`, `pnpm dev`
- **nx**: `nx affected -t lint`, `nx affected -t typecheck`, `nx affected -t build`, `nx affected -t test`, `nx serve`
- **cargo**: `cargo clippy`, `cargo check`, `cargo build`, `cargo test`, `cargo run`
- **go**: `golangci-lint run`, `go build`, `go build`, `go test ./...`, `go run .`
- **make**: `make lint`, `make check`, `make build`, `make test`, `make dev`

### Step 8: Create CLAUDE.md

Create the Claude Code instructions file based on user mode:

**For technical users:**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code when working with this project.

## Project Overview

**{Project Name}**: {Description}

## Project Documentation

Key project documents are stored in the `docs/` folder:
- `docs/PRD.md` - Product requirements document
- `docs/BRAND_GUIDE.md` - Brand and UX guidelines
- `docs/TESTING_STRATEGY.md` - Testing approach and strategy

## Configuration

Project settings are in `.claude/project.yaml`. This includes:
- Build commands and tooling
- Git branch conventions
- Project-management provider and statuses
- Team configuration

## Slash Commands

### Project Setup (`/fra:` commands)
- `/fra:status` - Check project setup progress
- `/fra:prd` - Define product requirements
- `/fra:brand` - Define brand and UX guidelines
- `/fra:testing` - Define testing strategy
- `/fra:setup-pm` - Create the project-management structure
- `/fra:save` - Commit and push changes

### Development (`/zao:` commands) — branch + PR workflow
- `/zao:workflow` - View the development workflow
- `/zao:begin-task TSK-XXX` - Start working on a task (creates a branch)
- `/zao:implement-task` - Build the planned task
- `/zao:test-task` - Run tests and checks
- `/zao:submit-task` - Create PR for review
- `/zao:finish-task` - Merge and complete task
- `/zao:check-status` - Check current task status
- `/zao:run-milestone <milestone>` - Run a whole milestone autonomously (Cairn only)
```

(Include the `/zao:run-milestone` line only when the provider is Cairn.)

**For non-technical users:**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code when working with this project.

## Communication Style

This project is configured for a non-technical user. Claude should:
- Use simple, everyday language instead of technical jargon
- Explain what's happening in terms of outcomes, not implementation
- Hide complex details unless specifically asked
- Guide through workflows step-by-step
- Translate technical errors into plain language
- Focus on "what" and "why" rather than "how"

## Project Overview

**{Project Name}**: {Description}

## Project Documentation

Project planning documents are in the `docs/` folder:
- `docs/PRD.md` - What we're building and why
- `docs/BRAND_GUIDE.md` - How it should look and feel
- `docs/TESTING_STRATEGY.md` - How we'll make sure it works

## How to Work on This Project

### Setting Up (do these once)
- `/fra:status` - See what's been set up
- `/fra:prd` - Describe what you want to build
- `/fra:brand` - Describe how it should look and feel
- `/fra:testing` - This gets generated automatically
- `/fra:setup-pm` - Create the project-management structure

### Working on Tasks (daily workflow)
- `/zao:workflow` - See an overview of how this works
- `/zao:begin-task TSK-XXX` - Start a task (get the code from your PM app)
- `/zao:check-status` - See where you are and what to do next
- `/zao:save` - Save your progress

### When You're Done
- `/zao:submit-task` - Send your work for review
- `/zao:finish-task` - Complete the task after approval
```

Write this to `CLAUDE.md` in the project root.

### Step 9: Create .gitignore

Detect project type and create appropriate `.gitignore`:

**For Node.js projects:**
```
node_modules/
dist/
build/
.next/
.env
.env.local
.env.*.local
.idea/
.vscode/
*.swp
*.swo
.DS_Store
Thumbs.db
*.log
npm-debug.log*
coverage/

# Claude Code artifacts
.playwright-mcp/
.changeset/
```

**For Rust projects:**
```
target/
Cargo.lock
.env
.idea/
.vscode/
*.swp
.DS_Store

# Claude Code artifacts
.playwright-mcp/
.changeset/
```

**For Go projects:**
```
bin/
vendor/
.env
.idea/
.vscode/
*.swp
.DS_Store

# Claude Code artifacts
.playwright-mcp/
.changeset/
```

**For Python projects:**
```
__pycache__/
*.py[cod]
*$py.class
.env
.venv/
venv/
.idea/
.vscode/
*.swp
.DS_Store
dist/
build/
*.egg-info/
.coverage
htmlcov/

# Claude Code artifacts
.playwright-mcp/
.changeset/
```

If `.gitignore` already exists, don't overwrite it.

### Step 10: Initial Commit

```bash
git add .
git commit -m "chore: initial project setup

- Initialize repository structure
- Add CLAUDE.md with project guidelines
- Add project configuration
- Create docs/ directory for project documentation

🤖 Generated with Claude Code"
```

### Step 11: Push to GitHub

```bash
git push -u origin main
```

If the default branch is `master`, rename it:
```bash
git branch -M main
git push -u origin main
```

### Step 12: Report Completion

**For technical users:**

---

**Project Initialized!**

**{Project Name}**

- **GitHub:** {repo URL}
- **Visibility:** Private
- **Build Tool:** {detected tool}
- **User Mode:** Technical

**What's been set up:**
- Git repository initialized
- Private GitHub repo created
- `.claude/project.yaml` configuration
- `CLAUDE.md` with project guidelines
- `docs/` folder for documentation
- `.gitignore` for {project type}

**Configuration:** Review `.claude/project.yaml` to customize build commands, team settings, and PM settings (`project_management.*`). If the provider is Cairn, register the `cairn` MCP server with `scripts/setup-mcp.sh` from the fra-zao-workflow repo, and consider limiting the repo's PR CI to `pull_request: branches: [{git.default_branch}, main]` so task PRs into `milestone/**` branches don't run it.

**Next step:** Start defining your product with `/fra:prd`

---

**For non-technical users:**

---

**Your Project is Ready!**

**{Project Name}** has been set up and saved to GitHub.

**What's been created:**
- A private space for your code on GitHub
- A folder for your project planning documents
- Configuration so Claude knows how to help you

**What to do next:**
1. Run `/fra:prd` to start describing what you want to build
2. Claude will guide you through some questions
3. Your answers will become the project plan

Just type `/fra:prd` when you're ready to start!

---

## Important

- The GitHub repo is always created as private for security
- The user mode setting affects how Claude communicates throughout all commands
- Build tool detection helps configure the right commands automatically
- Always write `project_management.provider` explicitly
- If any step fails, provide clear guidance on how to resolve it
