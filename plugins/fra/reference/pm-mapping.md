# PM provider mapping

This reference is the canonical, maintainer-facing source of truth for how the `/fra:*` and
`/zao:*` commands map abstract PM operations onto the Lakar and Note&Task MCP tools. It is
shipped identically in both the `fra` and `zao` plugins. **If you edit one copy, edit the
other** — they must stay byte-identical.

> Note: `${CLAUDE_PLUGIN_ROOT}` does not expand in command markdown, so commands do **not** load
> this file at runtime — each command inlines the subset of this table it needs. When you change
> a mapping here, update the inlined copies in the affected command files too.

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
