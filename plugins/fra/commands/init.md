---
description: Initialize a new project with git, GitHub repo, and Claude Code configuration
allowed-tools: AskUserQuestion, Bash, Write, Read
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
  lakar_client: ""  # Set this to your Lakar client name

git:
  default_branch: main
  branch_prefixes:
    feature: "feature/"
    bugfix: "fix/"
    hotfix: "hotfix/"
    chore: "chore/"
  merge_strategy: squash
  delete_branch_after_merge: true

build:
  tool: {build_tool}
  commands:
    lint: "{auto-detected or default}"
    typecheck: "{auto-detected or default}"
    build: "{auto-detected or default}"
    test: "{auto-detected or default}"
    dev: "{auto-detected or default}"
  dev_port: 3000

lakar:
  statuses:
    todo: "Todo"
    in_progress: "In Progress"
    in_review: "In Review"
    done: "Done"
    paused: null
    blocked: null

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
```

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
- Lakar workflow statuses
- Team configuration

## Slash Commands

### Project Setup (`/fra:` commands)
- `/fra:status` - Check project setup progress
- `/fra:prd` - Define product requirements
- `/fra:brand` - Define brand and UX guidelines
- `/fra:testing` - Define testing strategy
- `/fra:lakar` - Create Lakar project structure
- `/fra:save` - Commit and push changes

### Development (`/zao:` commands) — branch + PR workflow
- `/zao:workflow` - View the development workflow
- `/zao:begin-task TSK-XXX` - Start working on a task (creates a branch)
- `/zao:implement-task` - Build the planned task
- `/zao:test-task` - Run tests and checks
- `/zao:submit-task` - Create PR for review
- `/zao:finish-task` - Merge and complete task
- `/zao:check-status` - Check current task status
```

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
- `/fra:lakar` - Create tasks in Lakar

### Working on Tasks (daily workflow)
- `/zao:workflow` - See an overview of how this works
- `/zao:begin-task TSK-XXX` - Start a task (get the code from Lakar)
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

**Configuration:** Review `.claude/project.yaml` to customize build commands, team settings, and Lakar statuses.

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
- If any step fails, provide clear guidance on how to resolve it
