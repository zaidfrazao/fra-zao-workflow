# Multi-provider Project Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let each project flag whether the `/fra:*` and `/zao:*` workflow commands drive **Lakar** or **Note&Task** for project management, defaulting to Lakar when nothing is configured.

**Architecture:** Per-project `.claude/project.yaml` gains a `project_management:` block with a `provider` field. A single mapping reference (`reference/pm-mapping.md`, shipped identically in both plugins) translates abstract PM operations to the concrete `mcp__lakar__*` / `mcp__notetask__*` tool + field shapes. Every PM-touching command resolves the provider, then consults the mapping. A new HTTP MCP server `notetask` is registered alongside the existing five.

**Tech Stack:** Claude Code plugins (markdown command definitions), MCP servers (Lakar stdio/node, Note&Task HTTP/bearer), bash setup script, YAML config.

---

## Notes for the implementer (read first)

- **This repo is NOT a git repository.** The "Commit" steps below are written as `git` commands but will fail until someone runs `git init`. If git is unavailable, treat each Commit step as a **checkpoint**: re-read the changed file and confirm the edit landed, then continue. Do not skip the *verification* steps — only the commit itself is optional.
- **These are markdown prompt files, not executable code.** "Tests" are structural: `grep`/`diff`/`Read` assertions, plus one live MCP smoke test at the end. There is no test runner.
- **Spec:** `docs/superpowers/specs/2026-06-14-multi-provider-pm-design.md`. Keep it open.
- **The PM Resolution snippet** (defined in Task 4, Step 1) is inserted verbatim into many command bodies. It is repeated in each task that needs it so tasks can be read independently.

## File structure

**New files**
- `plugins/fra/reference/pm-mapping.md` — provider mapping (canonical copy)
- `plugins/zao/reference/pm-mapping.md` — byte-identical copy of the above
- `plugins/fra/commands/setup-pm.md` — new provider-aware structure builder

**Modified files**
- `scripts/setup-mcp.sh`, `.env.example`, `README.md`
- `plugins/fra/commands/`: `config.md`, `lakar.md`, `status.md`, `init.md`, `testing.md`
- `plugins/zao/commands/`: `begin-task.md`, `check-status.md`, `workflow.md`, `pause-task.md`, `resume-task.md`, `cancel-task.md`, `finish-task.md`, `submit-task.md`, `implement-task.md`, `fix-issue.md`, `adjust-feature.md`

---

## Task 1: Confirm `${CLAUDE_PLUGIN_ROOT}` substitution (spike)

The whole "shared reference doc" approach depends on command files being able to load `${CLAUDE_PLUGIN_ROOT}/reference/pm-mapping.md` at runtime. Confirm the variable resolves before building on it.

**Files:**
- Create (temporary): `plugins/zao/reference/_probe.md`
- Modify (temporary): `plugins/zao/commands/workflow.md`

- [ ] **Step 1: Add a probe reference file**

Create `plugins/zao/reference/_probe.md`:

```markdown
PROBE_OK
```

- [ ] **Step 2: Temporarily make workflow.md read it**

At the very top of the body of `plugins/zao/commands/workflow.md` (after frontmatter), add:

```markdown
DEBUG: Read the file `${CLAUDE_PLUGIN_ROOT}/reference/_probe.md` and print its contents verbatim, then continue.
```

- [ ] **Step 3: Run the command in the installed-plugin context**

In a Claude Code session with the `zao` plugin installed (or launched via `--plugin-dir plugins/zao`), run `/zao:workflow`.
Expected: the output includes `PROBE_OK`, proving `${CLAUDE_PLUGIN_ROOT}` resolved to the plugin directory.

- [ ] **Step 4: Decide path based on result**

- If `PROBE_OK` printed → `${CLAUDE_PLUGIN_ROOT}` works; proceed with the plan as written.
- If it did NOT resolve (literal `${CLAUDE_PLUGIN_ROOT}` or file-not-found) → **fallback**: instead of one shared file loaded by path, the mapping table from Task 2 is inlined as a collapsed `<details>` section at the bottom of each PM-touching command. In that case, Task 2 still authors the canonical content; Tasks 4–8 paste the table inline rather than referencing the path. Record the decision at the top of the plan file before continuing.

- [ ] **Step 5: Revert the probe**

Remove the DEBUG line from `plugins/zao/commands/workflow.md` and delete `plugins/zao/reference/_probe.md`.

```bash
rm plugins/zao/reference/_probe.md
git add -A && git commit -m "chore: spike CLAUDE_PLUGIN_ROOT availability"
```

---

## Task 2: Author the mapping reference doc

**Files:**
- Create: `plugins/fra/reference/pm-mapping.md`
- Create: `plugins/zao/reference/pm-mapping.md` (identical)

- [ ] **Step 1: Write the canonical mapping doc**

Create `plugins/fra/reference/pm-mapping.md` with exactly this content:

````markdown
# PM provider mapping

This reference is the single source of truth for how the `/fra:*` and `/zao:*` commands
talk to a project-management backend. It is shipped identically in both the `fra` and `zao`
plugins. **If you edit one copy, edit the other** — they must stay byte-identical.

## Resolving the provider

Read `.claude/project.yaml` and determine the provider:

1. If a `project_management:` block exists → use `project_management.provider`. If that key is
   missing inside the block, assume `lakar`.
2. Else if a legacy `lakar:` block exists → provider is `lakar`; read statuses from
   `lakar.statuses.*` and the client from `team.lakar_client`.
3. Else → provider is `lakar` with default status names (`Todo` / `In Progress` / `In Review`
   / `Done`).

Status **values** always come from config (`project_management.statuses.*`, or legacy
`lakar.statuses.*`). This doc only maps which **tool** and which **field name** to use.

## Config keys per provider

| Key | Lakar | Note&Task |
|---|---|---|
| `provider` | `lakar` | `notetask` |
| `client` | client name → resolve to `client_id` via `list_clients` | ignored |
| `project_identifier` | ignored | e.g. `NOTET`; identifies the project and prefixes task codes |
| `workspace` | ignored | workspace name → resolve to `workspaceId` via `list_workspaces` (label ops only) |
| `statuses.*` | `Todo`/`In Progress`/`In Review`/`Done` | `todo`/`in_progress`/`in_review`/`done` (also `backlog`, `canceled`) |

## Operation → tool mapping

Pass the **task code** (e.g. `TSK-123` for Lakar, `NOTET-8` for Note&Task) wherever a task is
identified. `<status>` means a value pulled from `statuses.*` in config.

| Operation | Lakar | Note&Task |
|---|---|---|
| Get a task by code | `mcp__lakar__get_task { id: CODE }` | `mcp__notetask__get_task { code: CODE }` |
| Set a task's status | `mcp__lakar__update_task { id: CODE, status: <status> }` | `mcp__notetask__update_task { code: CODE, phase: <status> }` |
| List tasks by status | `mcp__lakar__list_tasks { status: <status> }` | `mcp__notetask__list_tasks { phase: <status> }` |
| Add a comment | `mcp__lakar__create_comment { task_id: CODE, content }` (also needs `user_id`, see below) | `mcp__notetask__create_comment { code: CODE, content }` |
| List comments | `mcp__lakar__list_task_comments { task_id: CODE }` | `mcp__notetask__list_task_comments { code: CODE }` |
| Current user | `mcp__lakar__get_current_user` | `mcp__notetask__get_current_user` |
| List projects | `mcp__lakar__list_projects` | `mcp__notetask__list_projects` |
| Create project | `mcp__lakar__create_project { client_id, name, description }` | `mcp__notetask__create_project { name, identifier }` |
| List phases | `mcp__lakar__list_project_phases { project_id }` | `mcp__notetask__list_phases { projectIdentifier }` |
| Create phase | `mcp__lakar__create_phase { project_id, name, position }` | `mcp__notetask__create_phase { projectIdentifier, name }` |
| List milestones | `mcp__lakar__list_milestones { phase_id }` | `mcp__notetask__list_milestones { phaseId }` |
| Create milestone | `mcp__lakar__create_milestone { phase_id, name, position }` | `mcp__notetask__create_milestone { phaseId, name }` |
| Create task in milestone | `mcp__lakar__create_milestone_task { milestone_id, title, description, type, story_points, status: <status> }` | `mcp__notetask__create_task { projectIdentifier, milestoneId, title, description, taskType, priority, phase: <status> }` |
| List labels | `mcp__lakar__list_labels` | `mcp__notetask__list_labels { workspaceId }` |
| Create label | `mcp__lakar__create_label { name }` | `mcp__notetask__create_label { workspaceId, name, color }` |
| Assign label | `mcp__lakar__assign_label_to_task { task_id: CODE, label_id }` | `mcp__notetask__assign_label_to_task { code: CODE, labelId }` |

## Provider-specific gotchas

- **Lakar comments require `user_id`.** Call `mcp__lakar__get_current_user` once and reuse the
  UUID for every `create_comment`. Note&Task resolves the author from the API key — no `user_id`
  needed.
- **Lakar task `type`** field values: `Story` / `Bug` / `Feature` / `Chore` / `Technical Debt`.
  Note&Task uses `taskType` plus a separate `priority`; consult the live tool schema for its
  allowed values when creating tasks.
- **Project reference:** Lakar tools need the project UUID (`project_id` from `list_projects` /
  `create_project`). Note&Task tools accept `projectIdentifier` (from config
  `project_identifier`) — prefer it; only fall back to `projectId` if an identifier is unset.
- **Note&Task has `canceled`** as a real phase; map `/zao:cancel-task` to it when provider is
  notetask (Lakar has no native canceled state — use `Todo`/Backlog there).
- **Note&Task has `move_task`** for kanban repositioning; the workflow commands do not need it.
````

- [ ] **Step 2: Copy the file into the zao plugin**

```bash
cp plugins/fra/reference/pm-mapping.md plugins/zao/reference/pm-mapping.md
```

- [ ] **Step 3: Verify the two copies are identical**

Run: `diff plugins/fra/reference/pm-mapping.md plugins/zao/reference/pm-mapping.md`
Expected: no output (exit 0).

- [ ] **Step 4: Commit**

```bash
git add plugins/fra/reference/pm-mapping.md plugins/zao/reference/pm-mapping.md
git commit -m "feat: add PM provider mapping reference (lakar + notetask)"
```

---

## Task 3: Register the Note&Task MCP server

**Files:**
- Modify: `scripts/setup-mcp.sh`
- Modify: `.env.example`

- [ ] **Step 1: Add the notetask block to setup-mcp.sh**

In `scripts/setup-mcp.sh`, after the tavily block (the `[5/5] tavily` section ending at the
`fi` near line 111) and before the final `echo` summary, insert:

```bash
# ---- 6. notetask (http, bearer) --------------------------------------------------
echo "[6/6] notetask"
if [[ -z "${NOTETASK_API_KEY:-}" ]]; then
  echo "  ! NOTETASK_API_KEY not set — skipping notetask. Set it in .env to enable Note&Task PM." >&2
else
  add_server notetask --transport http https://note-task-mcp.genesis-apps.com/mcp \
    --header "Authorization: Bearer $NOTETASK_API_KEY"
fi
```

- [ ] **Step 2: Bump the step counters in the echoes**

Change the five existing `echo "[N/5] ..."` lines to `[N/6]`:
- `echo "[1/5] lakar"` → `echo "[1/6] lakar"`
- `echo "[2/5] pal"` → `echo "[2/6] pal"`
- `echo "[3/5] serena"` → `echo "[3/6] serena"`
- `echo "[4/5] context7"` → `echo "[4/6] context7"`
- `echo "[5/5] tavily"` → `echo "[5/6] tavily"`

- [ ] **Step 3: Update the closing summary line**

Change the final tools-list echo (currently ending `... mcp__tavily__*`) to include notetask:

```bash
echo "    Tools will resolve as mcp__lakar__*, mcp__pal__*, mcp__serena__*, mcp__context7__*, mcp__tavily__*, mcp__notetask__*"
```

- [ ] **Step 4: Confirm `add_server` forwards `--transport`/`--header`**

Read the `add_server()` helper (around line 47). It runs `claude mcp add "$name" --scope "$SCOPE" "$@"`,
so all extra args (`--transport`, the URL, `--header "..."`) pass straight through. No helper
change needed. Confirm by reading the function.

- [ ] **Step 5: Add NOTETASK_API_KEY to .env.example**

In `.env.example`, after the Tavily block and before the "Optional overrides" section, insert:

```bash
# Note&Task project management — used by /fra and /zao when a project sets
# project_management.provider: notetask in .claude/project.yaml
# Get one from your Note&Task account (MCP create_api_key returns it once).
NOTETASK_API_KEY=nt_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

- [ ] **Step 6: Verify the script parses**

Run: `bash -n scripts/setup-mcp.sh`
Expected: no output, exit 0 (syntax OK).

- [ ] **Step 7: Commit**

```bash
git add scripts/setup-mcp.sh .env.example
git commit -m "feat: register notetask MCP server in setup script"
```

---

## Task 4: Generalize the config schema (`/fra:config`)

**Files:**
- Modify: `plugins/fra/commands/config.md`

- [ ] **Step 1: Define the canonical PM Resolution snippet (reused later)**

This exact block is inserted into command bodies in later tasks. Keep it here for reference:

```markdown
### Project management provider

Before any task-tracking call:
1. Read `.claude/project.yaml`.
2. If a `project_management:` block exists, use `project_management.provider` (assume `lakar`
   if the key is missing). Else if a legacy `lakar:` block exists, treat the provider as
   `lakar`. Else default to `lakar`.
3. Load `${CLAUDE_PLUGIN_ROOT}/reference/pm-mapping.md` and use the mapping for the resolved
   provider. Status values come from `project_management.statuses.*` (or legacy
   `lakar.statuses.*`).
```

- [ ] **Step 2: Replace the config question for Lakar client with provider questions**

In `plugins/fra/commands/config.md`, in "Step 2: Gather Project Information", replace question 6
("What is your Lakar client name?") with:

```markdown
6. "Which project-management app should this project use?"
   - Options:
     - **Lakar** (default) - the original backend
     - **Note&Task** - alternative PM app

7. If **Lakar**: "What is your Lakar client name?" (optional, can be left blank)

8. If **Note&Task**:
   - "What project identifier should tasks use? (1–6 uppercase letters/digits, e.g. NOTET)"
   - Resolve the workspace: call `mcp__notetask__list_workspaces`. If exactly one, use it
     silently; if several, ask which; store its name.
```

- [ ] **Step 3: Replace the `team` + `lakar` blocks in the generated YAML**

In "Step 6: Generate Configuration", replace the `team:` block and the `lakar:` block with:

```yaml
team:
  lead: "{team-lead or empty}"

project_management:
  provider: {provider}            # lakar | notetask  (default lakar)
  client: "{lakar-client or empty}"      # lakar only (was team.lakar_client)
  project_identifier: "{identifier or empty}"  # notetask only
  workspace: "{workspace or empty}"            # notetask only
  statuses:
    todo: "{Todo | todo}"
    in_progress: "{In Progress | in_progress}"
    in_review: "{In Review | in_review}"
    done: "{Done | done}"
    paused: null
    blocked: null
    canceled: null
```

Add a note directly under the YAML block:

```markdown
Use Lakar status names (`Todo`, `In Progress`, …) when `provider: lakar`; use Note&Task phase
values (`todo`, `in_progress`, `in_review`, `done`, and `canceled`) when `provider: notetask`.
```

- [ ] **Step 4: Add a migration rule to the "Handling Updates" section**

Append to the "Handling Updates" section of `config.md`:

```markdown
### Migrating a legacy config

If the existing file has a top-level `lakar:` block and/or `team.lakar_client` but no
`project_management:` block:
1. Create `project_management:` with `provider: lakar`.
2. Move `team.lakar_client` → `project_management.client` (then remove `lakar_client` from `team`).
3. Move `lakar.statuses.*` → `project_management.statuses.*` verbatim.
4. Remove the old top-level `lakar:` block.
Preserve every value exactly; only the location changes.
```

- [ ] **Step 5: Add notetask tools to allowed-tools**

Change the frontmatter `allowed-tools` line of `config.md` from:

```
allowed-tools: AskUserQuestion, Bash, Read, Write
```
to:
```
allowed-tools: AskUserQuestion, Bash, Read, Write, mcp__notetask__list_workspaces
```

- [ ] **Step 6: Verify**

Run: `grep -n "project_management" plugins/fra/commands/config.md`
Expected: matches in the YAML block and the migration section.
Run: `grep -n "lakar_client" plugins/fra/commands/config.md`
Expected: only the migration-section reference remains (no longer in the generated YAML).

- [ ] **Step 7: Commit**

```bash
git add plugins/fra/commands/config.md
git commit -m "feat: generalize project.yaml to project_management block in /fra:config"
```

---

## Task 5: New `/fra:setup-pm` command + `/fra:lakar` forwarder

**Files:**
- Create: `plugins/fra/commands/setup-pm.md`
- Modify: `plugins/fra/commands/lakar.md`

- [ ] **Step 1: Create setup-pm.md from the current lakar.md, made provider-aware**

Create `plugins/fra/commands/setup-pm.md`. Start from the **entire current body** of
`plugins/fra/commands/lakar.md`, then apply these changes:

1. Frontmatter `description`:
```
description: Create the project-management structure (phases, milestones, tasks) from the PRD, Brand Guide, and Testing Strategy — works with Lakar or Note&Task
```

2. Frontmatter `allowed-tools` — add the notetask equivalents:
```
allowed-tools: AskUserQuestion, Read, mcp__lakar__list_clients, mcp__lakar__list_projects, mcp__lakar__get_project, mcp__lakar__create_project, mcp__lakar__update_project, mcp__lakar__list_phases, mcp__lakar__list_project_phases, mcp__lakar__create_phase, mcp__lakar__update_phase, mcp__lakar__list_milestones, mcp__lakar__create_milestone, mcp__lakar__update_milestone, mcp__lakar__create_milestone_task, mcp__lakar__list_tasks, mcp__lakar__create_task, mcp__lakar__update_task, mcp__lakar__list_labels, mcp__lakar__create_label, mcp__lakar__assign_label_to_task, mcp__notetask__list_workspaces, mcp__notetask__list_projects, mcp__notetask__get_project, mcp__notetask__create_project, mcp__notetask__list_phases, mcp__notetask__create_phase, mcp__notetask__list_milestones, mcp__notetask__create_milestone, mcp__notetask__create_task, mcp__notetask__list_tasks, mcp__notetask__list_labels, mcp__notetask__create_label, mcp__notetask__assign_label_to_task, mcp__pal__planner
```

3. After the title line, insert the PM Resolution snippet:
```markdown
### Project management provider

Before any structure call:
1. Read `.claude/project.yaml`.
2. If a `project_management:` block exists, use `project_management.provider` (assume `lakar`
   if the key is missing). Else if a legacy `lakar:` block exists, treat the provider as
   `lakar`. Else default to `lakar`.
3. Load `${CLAUDE_PLUGIN_ROOT}/reference/pm-mapping.md` and use the mapping for the resolved
   provider. Status values come from `project_management.statuses.*` (or legacy
   `lakar.statuses.*`).
```

4. Replace "Step 2 of the config read" reference: change the line
   `2. **Read `.claude/project.yaml`** for `user.mode`, `project.name`, `project.type`, and `lakar.statuses.*`.`
   to:
   `2. **Read `.claude/project.yaml`** for `user.mode`, `project.name`, `project.type`, and the resolved provider + statuses (see "Project management provider" above).`

5. Make "Step 1: Select or create the client" provider-aware. Replace its body with:
```markdown
### Step 1: Select the owning scope

- **Lakar:** `mcp__lakar__list_clients` → ask which client should own the project (or stop and
  direct the user to create one in the Lakar UI if none exist). Record `client_id`.
- **Note&Task:** there are no clients. Skip client selection. If a workspace is needed later for
  labels, use `project_management.workspace` from config (resolve via
  `mcp__notetask__list_workspaces` if unset).
```

6. Make "Step 2: Select or create the project" provider-aware. Replace the Create path line with:
```markdown
- Create path:
  - **Lakar:** `mcp__lakar__create_project { client_id, name: project.name, description: project.description }`. Store the returned `project_id`.
  - **Note&Task:** `mcp__notetask__create_project { name: project.name, identifier: project_management.project_identifier }`. Store the returned project id and identifier.
```

7. For Steps 4, 6, 7, 10 (create phase/milestone/labels/tasks) and Step 12 (summary), add a
   leading note to each: "Use the provider-correct tool from `pm-mapping.md`." Specifically, in
   Step 7 (labels) note: "Note&Task `create_label` requires `workspaceId` — use the resolved
   workspace." In Step 12 summary, change the header `**Lakar project populated**` to
   `**Project management structure populated** (provider: {provider})` and make the `Client:`
   line conditional (omit for notetask).

- [ ] **Step 2: Verify setup-pm.md references both providers**

Run: `grep -nE "mcp__notetask__create_project|mcp__lakar__create_project|pm-mapping" plugins/fra/commands/setup-pm.md`
Expected: all three patterns present.

- [ ] **Step 3: Replace lakar.md with a thin deprecated forwarder**

Overwrite `plugins/fra/commands/lakar.md` with:

```markdown
---
description: (Deprecated alias for /fra:setup-pm) Create the project-management structure from the planning docs
allowed-tools: Read
---

`/fra:lakar` is a deprecated alias kept for backward compatibility.

Run the **`/fra:setup-pm`** command instead — it builds the phase/milestone/task structure for
whichever provider the project is configured to use (Lakar or Note&Task). Follow every
instruction in `${CLAUDE_PLUGIN_ROOT}/commands/setup-pm.md` exactly as if the user had invoked
`/fra:setup-pm`.
```

- [ ] **Step 4: Verify the forwarder**

Run: `grep -c "mcp__lakar__create" plugins/fra/commands/lakar.md`
Expected: `0` (the heavy logic moved to setup-pm.md).

- [ ] **Step 5: Commit**

```bash
git add plugins/fra/commands/setup-pm.md plugins/fra/commands/lakar.md
git commit -m "feat: add /fra:setup-pm; make /fra:lakar a deprecated forwarder"
```

---

## Task 6: Update remaining fra commands (status, init, testing)

**Files:**
- Modify: `plugins/fra/commands/status.md`
- Modify: `plugins/fra/commands/init.md`
- Modify: `plugins/fra/commands/testing.md`

- [ ] **Step 1: status.md — provider-aware project check**

In `plugins/fra/commands/status.md`:

1. Frontmatter — change `allowed-tools` from:
```
allowed-tools: Bash, Read, mcp__lakar__list_projects, mcp__lakar__list_clients
```
to:
```
allowed-tools: Bash, Read, mcp__lakar__list_projects, mcp__lakar__list_clients, mcp__notetask__list_projects, mcp__notetask__list_workspaces
```

2. In "Step 2: Check Lakar project status", replace the two bullets with:
```markdown
   - Determine the provider from `.claude/project.yaml` (`project_management.provider`, default
     `lakar`).
   - **Lakar:** `mcp__lakar__list_clients` + `mcp__lakar__list_projects`.
   - **Note&Task:** `mcp__notetask__list_projects` (match on `project_management.project_identifier`).
```

3. In the status table (Step 3) and the "next step recommendation" (Step 4), change every
   `/fra:lakar` reference to `/fra:setup-pm` and rename the table row label `Lakar Project` to
   `PM Structure`.

- [ ] **Step 2: init.md — generalize the emitted config + command references**

In `plugins/fra/commands/init.md`:

1. The emitted config currently has (around line 92) `lakar_client: ""  # Set this to your Lakar client name` inside a `team:` block, and (around line 114) a `lakar:` block. Replace the `lakar_client` line and the entire `lakar:` block so the generated `project.yaml` instead emits:
```yaml
project_management:
  provider: lakar            # lakar | notetask
  client: ""                 # lakar only — your Lakar client name
  project_identifier: ""     # notetask only — e.g. NOTET
  workspace: ""              # notetask only
  statuses:
    todo: "Todo"
    in_progress: "In Progress"
    in_review: "In Review"
    done: "Done"
    paused: null
    blocked: null
    canceled: null
```
(Remove `lakar_client` from the `team:` block; leave `team.lead`.)

2. Replace the two command references (lines ~187 and ~235) `/fra:lakar - Create Lakar project structure` and `/fra:lakar - Create tasks in Lakar` with `/fra:setup-pm - Create the project-management structure`.

- [ ] **Step 3: testing.md — update next-step pointers**

In `plugins/fra/commands/testing.md`, change both `/fra:lakar` next-step references
(lines ~363 and ~384) to `/fra:setup-pm`, and reword "create your Lakar project structure" /
"create your task list in Lakar" to "create your project-management structure".

- [ ] **Step 4: Verify no stray /fra:lakar prose remains except the forwarder**

Run: `grep -rn "/fra:lakar" plugins/`
Expected: matches only in `plugins/fra/commands/lakar.md` (the deprecated forwarder may name itself). All other files reference `/fra:setup-pm`.

- [ ] **Step 5: Commit**

```bash
git add plugins/fra/commands/status.md plugins/fra/commands/init.md plugins/fra/commands/testing.md
git commit -m "feat: point fra status/init/testing at /fra:setup-pm and project_management config"
```

---

## Task 7: Make status-changing zao commands provider-aware

These commands read config, fetch a task, change its status, and/or comment:
`begin-task`, `check-status`, `workflow`, `pause-task`, `resume-task`, `cancel-task`,
`finish-task`, `submit-task`.

For **each** file below, apply the same two edits: (a) extend `allowed-tools` with the parallel
notetask tools, and (b) insert the PM Resolution snippet near the top of the body, and (c)
reword status-update / comment instructions to "use the provider-correct tool from
`pm-mapping.md`". The exact per-file tool additions follow.

**The PM Resolution snippet (insert verbatim after the command's first paragraph in each file):**

```markdown
### Project management provider

Before any task-tracking call:
1. Read `.claude/project.yaml`.
2. If a `project_management:` block exists, use `project_management.provider` (assume `lakar`
   if the key is missing). Else if a legacy `lakar:` block exists, treat the provider as
   `lakar`. Else default to `lakar`.
3. Load `${CLAUDE_PLUGIN_ROOT}/reference/pm-mapping.md` and use the mapping for the resolved
   provider. Status values come from `project_management.statuses.*` (or legacy
   `lakar.statuses.*`). Where instructions below name an `mcp__lakar__*` tool, use the
   provider's equivalent from that mapping.
```

- [ ] **Step 1: begin-task.md**

`allowed-tools`: add `mcp__notetask__get_task, mcp__notetask__update_task` after the lakar pair.
Insert the snippet after the first line (`Start working on the Lakar task: $ARGUMENTS`).
In the body, the references to `mcp__lakar__get_task` (step 1) and `mcp__lakar__update_task`
(step 3, set `{lakar.statuses.in_progress}`) keep working for lakar; add "(or the notetask
equivalent per pm-mapping.md; status value from `project_management.statuses.in_progress`)".

- [ ] **Step 2: check-status.md**

`allowed-tools`: change `mcp__lakar__get_task, Bash` → `mcp__lakar__get_task, mcp__notetask__get_task, Bash`.
Insert the snippet after the first paragraph. In step 1d, note the task fetch uses the
provider's `get_task`. In step 3's table, the row keys ("Lakar Todo", "Lakar In Progress",
etc.) read the status from config rather than hardcoded — add a note: "status names come from
`project_management.statuses.*`; for notetask they are lowercase (`todo`, `in_progress`, …)".

- [ ] **Step 3: workflow.md**

`allowed-tools`: change `mcp__lakar__get_task, mcp__lakar__list_tasks, Bash` →
`mcp__lakar__get_task, mcp__lakar__list_tasks, mcp__notetask__get_task, mcp__notetask__list_tasks, Bash`.
Insert the snippet after the first paragraph. Update the line "If a Lakar task is detected,
fetch its current status using `mcp__lakar__get_task`" to add "(or the notetask equivalent)".

- [ ] **Step 4: pause-task.md**

`allowed-tools`: add `mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user`.
Insert the snippet after the first paragraph. At the existing "Important" bullet about
`create_comment` requiring `user_id`, append: "This applies to Lakar only — Note&Task resolves
the author from the API key, so skip `get_current_user`/`user_id` when provider is notetask."

- [ ] **Step 5: resume-task.md**

`allowed-tools`: add `mcp__notetask__get_task, mcp__notetask__list_task_comments, mcp__notetask__update_task`.
Insert the snippet after the first paragraph. The "set status back to In Progress" step reads
the value from `project_management.statuses.in_progress`.

- [ ] **Step 6: cancel-task.md**

`allowed-tools`: add `mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user`.
Insert the snippet after the first paragraph. At the step that sets status to "Backlog" or
"Todo", add: "For notetask, prefer the `canceled` phase (`project_management.statuses.canceled`)
if set, else `todo`." Append the same `user_id`-is-lakar-only note as in Step 4.

- [ ] **Step 7: finish-task.md**

`allowed-tools`: add `mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user`.
Insert the snippet after the first paragraph. The "set status to {lakar.statuses.done}" and the
closing-comment steps use the provider's tools. Append the `user_id`-is-lakar-only note to the
existing `create_comment` "Important" bullet.

- [ ] **Step 8: submit-task.md**

`allowed-tools`: add `mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user`.
Insert the snippet after the first paragraph. The "set status to {lakar.statuses.in_review}" and
technical-notes-comment steps use the provider's tools. Append the `user_id`-is-lakar-only note
to the existing `create_comment` "Important" bullet.

- [ ] **Step 9: Verify allowed-tools coverage for status commands**

Run:
```bash
for f in begin-task check-status workflow pause-task resume-task cancel-task finish-task submit-task; do
  echo "== $f =="; grep -m1 "allowed-tools" plugins/zao/commands/$f.md | grep -o "mcp__notetask__[a-z_]*" | sort -u
done
```
Expected: each file lists at least `mcp__notetask__get_task`; comment-writing files also list
`mcp__notetask__create_comment` and `mcp__notetask__get_current_user`.

- [ ] **Step 10: Verify the snippet landed in each**

Run: `grep -L "Project management provider" plugins/zao/commands/{begin-task,check-status,workflow,pause-task,resume-task,cancel-task,finish-task,submit-task}.md`
Expected: no output (every file contains the snippet).

- [ ] **Step 11: Commit**

```bash
git add plugins/zao/commands/{begin-task,check-status,workflow,pause-task,resume-task,cancel-task,finish-task,submit-task}.md
git commit -m "feat: make status-changing zao commands provider-aware"
```

---

## Task 8: Make read-only-context zao commands provider-aware

`implement-task`, `fix-issue`, `adjust-feature` only call `get_task` for context.

- [ ] **Step 1: Add notetask get_task to each frontmatter**

In each of `plugins/zao/commands/implement-task.md`, `fix-issue.md`, `adjust-feature.md`,
change the leading `mcp__lakar__get_task,` in `allowed-tools` to
`mcp__lakar__get_task, mcp__notetask__get_task,`.

- [ ] **Step 2: Insert the PM Resolution snippet into each**

Insert this block after the first paragraph of each of the three files:

```markdown
### Project management provider

This command only reads task context. Read `.claude/project.yaml`; if
`project_management.provider` is `notetask` (default `lakar`), fetch the task with
`mcp__notetask__get_task { code: CODE }` instead of `mcp__lakar__get_task`. See
`${CLAUDE_PLUGIN_ROOT}/reference/pm-mapping.md`.
```

- [ ] **Step 3: Verify**

Run: `grep -L "mcp__notetask__get_task" plugins/zao/commands/{implement-task,fix-issue,adjust-feature}.md`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add plugins/zao/commands/{implement-task,fix-issue,adjust-feature}.md
git commit -m "feat: make implement/fix/adjust zao commands provider-aware for task fetch"
```

---

## Task 9: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the MCP servers prose and table**

In `README.md`:
1. In the "Wire up the MCP servers" section, change "five MCP servers" / "all five" wording to
   "six MCP servers", and add `mcp__notetask__*` to the plain-names list.
2. Add a row to the server table:
```
| `notetask` | http (bearer) | `NOTETASK_API_KEY` *(optional)* | task tracking for projects flagged `provider: notetask` |
```

- [ ] **Step 2: Document provider selection + the mapping-doc sync rule**

Add a short subsection under "Notes":

```markdown
- **Choosing a PM backend per project.** Set `project_management.provider` to `lakar` (default)
  or `notetask` in `.claude/project.yaml`. Projects with no `project_management` block fall back
  to Lakar, so existing projects are unaffected. `/fra:config` migrates a legacy `lakar:` config.
- **`/fra:lakar` is deprecated** in favor of `/fra:setup-pm` (provider-aware). The old name
  still works as an alias.
- **Mapping doc must stay in sync.** `plugins/fra/reference/pm-mapping.md` and
  `plugins/zao/reference/pm-mapping.md` are byte-identical copies — edit both. CI/verification:
  `diff plugins/fra/reference/pm-mapping.md plugins/zao/reference/pm-mapping.md`.
```

- [ ] **Step 3: Update the Commands table**

In the `/fra` commands table, change the `/fra:lakar` row to `/fra:setup-pm` with purpose
"Build the phase/milestone/task structure (Lakar or Note&Task)".

- [ ] **Step 4: Verify**

Run: `grep -n "notetask\|setup-pm\|project_management" README.md`
Expected: matches in the table, notes, and commands sections.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: document notetask provider, /fra:setup-pm, mapping-doc sync"
```

---

## Task 10: Final verification

- [ ] **Step 1: Mapping docs identical**

Run: `diff plugins/fra/reference/pm-mapping.md plugins/zao/reference/pm-mapping.md`
Expected: no output.

- [ ] **Step 2: Every PM-touching command can reach notetask**

Run:
```bash
grep -rL "mcp__notetask__" \
  plugins/zao/commands/{begin-task,check-status,workflow,pause-task,resume-task,cancel-task,finish-task,submit-task,implement-task,fix-issue,adjust-feature}.md \
  plugins/fra/commands/{setup-pm,config,status}.md
```
Expected: no output (every listed file references a notetask tool).

- [ ] **Step 3: No command still hardcodes /fra:lakar as the action**

Run: `grep -rn "/fra:lakar" plugins/ README.md`
Expected: matches only in the deprecated forwarder `plugins/fra/commands/lakar.md` and the
README note describing the deprecation.

- [ ] **Step 4: Live smoke test (manual, requires notetask registered)**

In a throwaway project with `.claude/project.yaml` set to:
```yaml
project_management:
  provider: notetask
  project_identifier: NOTET
  statuses: { todo: todo, in_progress: in_progress, in_review: in_review, done: done, canceled: canceled }
```
- Run `/zao:check-status` → it should fetch via `mcp__notetask__get_task` (or report "no active
  task") without touching Lakar.
- Optionally run `/fra:setup-pm` against a scratch Note&Task project and confirm a phase +
  milestone + task get created.

- [ ] **Step 5: Backward-compat smoke test**

In a project whose `.claude/project.yaml` still has the **legacy** `lakar:` block and no
`project_management:`, run `/zao:check-status`. Expected: behaves exactly as before (provider
resolves to `lakar`).

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "test: final verification for multi-provider PM"
```

---

## Self-review (completed by plan author)

- **Spec coverage:** §1 config → Tasks 4, 6; §2 mapping doc → Task 2; §3 command changes →
  Tasks 5, 6, 7, 8; §4 workspace resolution → Tasks 4, 5; §5 MCP registration → Task 3;
  README/testing → Task 9; verification plan → Task 10. All spec sections mapped.
- **Default-to-lakar rule** (user requirement) appears in the PM Resolution snippet (every
  command) and in the mapping doc's "Resolving the provider" section.
- **Placeholder scan:** the only deferred decision is Task 1's `${CLAUDE_PLUGIN_ROOT}` spike,
  which has an explicit fallback — not a placeholder.
- **Naming consistency:** `project_management`, `provider`, `pm-mapping.md`, `/fra:setup-pm`
  used consistently across all tasks.
