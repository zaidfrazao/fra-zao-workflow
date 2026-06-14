# Multi-provider project management (Lakar + Note&Task)

**Date:** 2026-06-14
**Status:** Approved (design)

## Problem

The `/fra:*` and `/zao:*` workflow commands hard-wire **Lakar** as the project-management
backend (tools `mcp__lakar__*`, the `lakar:` config block, the `/fra:lakar` command name).
We want to flag *certain projects* to use a different app — **Note&Task** (MCP server
`notetask`, HTTP transport) — for project management, while every existing project keeps
working unchanged.

## Goal

Per-project choice of PM backend, driven by `.claude/project.yaml`. A project that does not
set a provider **defaults to Lakar** — no existing project requires any change.

## Non-goals

- No data migration between Lakar and Note&Task.
- No support for more than these two providers (the abstraction should not preclude a third,
  but we are not building one).
- No change to non-PM behavior (git, PRs, build/test, brand/PRD/testing docs).

## Background: the two tool surfaces

The Note&Task MCP surface (`serverInfo.version` 0.3.0) is ~80% parallel to Lakar's. The
differences that the design must absorb:

| Concern | Lakar | Note&Task |
|---|---|---|
| Task status | field `status`: `Todo / In Progress / In Review / Done` | field `phase`: `backlog / todo / in_progress / in_review / done / canceled` |
| Task identity | `TSK-123` (global), arg `id` (accepts code or UUID) | `NOTET-8` (per-project identifier), arg `code` / `id` / `search` |
| Hierarchy root | project nests under a **client** (`client_id`) | project is **user-owned**; **workspace** matters only for labels |
| Project ref | `project_id` (UUID) | `projectId` (UUID) **or** `projectIdentifier` (e.g. `NOTET`) |
| Create task under milestone | `create_milestone_task {milestone_id}` | `create_task {projectIdentifier|projectId, milestoneId}` |
| Label creation | `create_label` (no workspace) | `create_label {workspaceId}` |
| Transport / auth | stdio (node), `LAKAR_API_KEY` env | HTTP, `Authorization: Bearer <NOTETASK_API_KEY>` |

Tool names that are identical (same name, possibly different arg names) include:
`list_projects, get_project, create_project, update_project, delete_project, create_phase,
update_phase, delete_phase, get_phase, create_milestone, update_milestone, delete_milestone,
get_milestone, list_milestones, list_tasks, get_task, create_task, update_task,
batch_update_tasks, delete_task, list_labels, get_label, create_label, update_label,
delete_label, assign_label_to_task, remove_label_from_task, create_comment,
list_task_comments, update_comment, delete_comment, get_current_user`.

Lakar-only: `list_clients / create_client / get_client / update_client / delete_client`,
`list_project_phases`, `list_phase_milestones`, `get_task_attachments`, `get_task_history`,
`get_task_time_entries`, `log_time`, `search`, `health_check`, whitelist/api-key tools.

Note&Task-only: `list_workspaces`, `list_phases` (project-scoped phase list), `move_task`
(kanban reposition), api-key tools.

## Design

### 1. Config schema

The `lakar:` block in `.claude/project.yaml` is generalized to `project_management:`. The
old `team.lakar_client` value moves under it as `client`.

```yaml
project_management:
  provider: lakar              # lakar | notetask  — DEFAULT lakar when omitted
  client: "Acme"               # lakar only (formerly team.lakar_client); ignored for notetask
  project_identifier: "NOTET"  # notetask only — resolves the project and parses task codes
  workspace: "My Workspace"    # notetask only — for label ops; auto-resolved at setup
  statuses:
    todo: "Todo"               # values shown are Lakar's; a notetask project uses "todo" etc.
    in_progress: "In Progress"
    in_review: "In Review"
    done: "Done"
    paused: null               # optional; provider value or null if unsupported
    blocked: null              # optional
    canceled: null             # optional (notetask supports "canceled")
```

**Backward compatibility / default-to-lakar resolution rule**, applied by every command that
reads PM config:

1. If `project_management:` exists → use it. `provider` defaults to `lakar` if that key is
   missing inside the block.
2. Else if a legacy `lakar:` block exists → treat as `provider: lakar`, reading statuses from
   `lakar.statuses.*` and client from `team.lakar_client`.
3. Else → `provider: lakar` with the default Lakar status names above.

No existing project file needs editing. `/fra:config` migrates a legacy file to the new shape
on its next run (preserving values).

### 2. Mapping reference doc (single source of truth)

A new file `reference/pm-mapping.md` is shipped in **both** plugins
(`plugins/fra/reference/pm-mapping.md` and `plugins/zao/reference/pm-mapping.md`), kept
byte-identical. Commands load it at runtime via `${CLAUDE_PLUGIN_ROOT}/reference/pm-mapping.md`
(Claude Code substitutes the plugin root in command files).

> **Sync requirement:** the two copies must stay identical. The README documents this, and the
> implementation plan includes a check (e.g. `diff` the two files) as a verification step.

The doc defines, for each **abstract operation**, the concrete tool and argument shape per
provider. Canonical operations and their mapping:

| Abstract op | Lakar | Note&Task |
|---|---|---|
| get task by code | `mcp__lakar__get_task {id: CODE}` | `mcp__notetask__get_task {code: CODE}` |
| set task status | `mcp__lakar__update_task {id, status: <statuses.X>}` | `mcp__notetask__update_task {code, phase: <statuses.X>}` |
| list tasks by status | `mcp__lakar__list_tasks {status}` | `mcp__notetask__list_tasks {phase}` |
| add comment | `mcp__lakar__create_comment {task_id: CODE, content}` | `mcp__notetask__create_comment {code: CODE, content}` |
| list comments | `mcp__lakar__list_task_comments {task_id}` | `mcp__notetask__list_task_comments {code}` |
| create project | `mcp__lakar__create_project {client_id, name}` | `mcp__notetask__create_project {name, identifier}` |
| list phases | `mcp__lakar__list_project_phases {project_id}` | `mcp__notetask__list_phases {projectIdentifier}` |
| create phase | `mcp__lakar__create_phase {...}` | `mcp__notetask__create_phase {projectIdentifier, name}` |
| create milestone | `mcp__lakar__create_milestone {...}` | `mcp__notetask__create_milestone {...}` |
| create task under milestone | `mcp__lakar__create_milestone_task {milestone_id, ...}` | `mcp__notetask__create_task {projectIdentifier, milestoneId, ...}` |
| create label | `mcp__lakar__create_label {name}` | `mcp__notetask__create_label {workspaceId, name}` |
| assign label | `mcp__lakar__assign_label_to_task {task_id, label_id}` | `mcp__notetask__assign_label_to_task {code, labelId}` |

Rules the doc states explicitly:
- **Status field name** differs: Lakar `status`, Note&Task `phase`. The *value* always comes
  from `project_management.statuses.*` in config.
- **Task identity**: pass the task code; Lakar via `id`, Note&Task via `code`.
- **Project reference**: Lakar needs the project UUID (`project_id`); Note&Task accepts
  `projectIdentifier` (from config `project_identifier`) — prefer it to avoid a UUID lookup.
- **Client vs workspace**: Lakar `create_project` needs `client_id` (resolve from
  `project_management.client` via `list_clients`); Note&Task ignores clients and needs
  `workspaceId` only for label creation (resolve from `project_management.workspace` via
  `list_workspaces`).

### 3. Command changes

Every command that performs a PM operation: (a) resolves the provider via the rule in §1,
(b) consults `${CLAUDE_PLUGIN_ROOT}/reference/pm-mapping.md`, (c) calls the provider-correct
tool. Each such command's `allowed-tools` frontmatter gains the parallel `mcp__notetask__*`
tools alongside the existing `mcp__lakar__*` ones.

**fra plugin**
- `config.md` — emit the new `project_management:` schema; ask `provider` (lakar/notetask) and
  provider-specific fields (`client` for lakar; `project_identifier` + workspace auto-resolve
  for notetask); migrate a legacy `lakar:`/`team.lakar_client` config when updating.
- `lakar.md` — becomes a **thin forwarder**: its body just invokes the same logic as
  `/fra:setup-pm` (kept for backward compatibility, marked deprecated in its description).
- `setup-pm.md` — **new** provider-aware command (the real structure builder). For lakar:
  create under client (current behavior). For notetask: create project with `identifier`,
  auto-resolve workspace (see §4), then build phases/milestones/tasks via the mapped tools.
- `status.md`, `init.md`, `testing.md` — update PM references and any emitted config/CLAUDE.md
  text to the generalized vocabulary and default-to-lakar rule.

**zao plugin** — provider-aware via the mapping doc:
`begin-task, implement-task, fix-issue, adjust-feature, check-status, submit-task,
finish-task, pause-task, resume-task, cancel-task, workflow`.

### 4. Note&Task workspace resolution

During `/fra:setup-pm` when `provider: notetask`: call `mcp__notetask__list_workspaces`.
If the user belongs to exactly one workspace, use it silently; if several, ask which; store the
result in `project_management.workspace`. Label operations later read it from config.

### 5. MCP registration

- `scripts/setup-mcp.sh` — add a 6th server, HTTP transport with bearer auth, registered in the
  same scope as the others (user scope by default) so it is available in any repo that flags it:
  ```bash
  add_server notetask --transport http https://note-task-mcp.genesis-apps.com/mcp \
    --header "Authorization: Bearer $NOTETASK_API_KEY"
  ```
  Skip with a warning if `NOTETASK_API_KEY` is unset (same pattern as the optional servers).
  Verify `add_server` supports `--transport`/`--header` passthrough; the helper forwards extra
  args to `claude mcp add`, so it should — confirm during implementation.
- `.env.example` — add `NOTETASK_API_KEY=nt_xxxxxxxx...` with a one-line comment.
- `README.md` — update "five MCP servers" → six; add a row to the server table
  (`notetask | http | NOTETASK_API_KEY (optional) | PM for flagged projects`); note the
  default-to-lakar rule and the `reference/pm-mapping.md` sync requirement.

## Testing / verification

This repo is a set of Claude Code command (markdown) definitions, not executable code, so
verification is structural:

1. **Mapping docs identical** — `diff plugins/fra/reference/pm-mapping.md plugins/zao/reference/pm-mapping.md` returns nothing.
2. **No stray hard-wiring** — grep the updated commands: any `mcp__lakar__` call that performs a
   PM op is reached only after a provider check (or is a lakar-only branch).
3. **allowed-tools coverage** — every command that can call a `notetask` tool lists it in
   `allowed-tools`.
4. **Config round-trip** — `/fra:config` on (a) a legacy `lakar:` config migrates to
   `project_management:` preserving values, (b) a config with no PM block yields `provider:
   lakar` behavior.
5. **Live smoke test (manual)** — with `notetask` registered: a project flagged
   `provider: notetask` can run `/fra:setup-pm` (creates project + structure) and
   `/zao:begin-task <CODE>` (fetches task, sets phase `in_progress`).

## Open risks

- `${CLAUDE_PLUGIN_ROOT}` substitution in command bodies must be confirmed available in the
  installed-plugin context (not only local `--plugin-dir`). If unavailable, fall back to
  inlining the mapping table into each command. Confirm early in implementation.
- The Note&Task token in `.env`/`~/.claude.json` is per-user; a single shared token is assumed,
  matching how the other keys are handled.
