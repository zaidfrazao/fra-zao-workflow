---
description: Create the project-management structure (phases, milestones, tasks) from the PRD, Brand Guide, and Testing Strategy — works with Lakar, Note&Task or Cairn
allowed-tools: AskUserQuestion, Read, Bash, Skill, mcp__lakar__list_clients, mcp__lakar__list_projects, mcp__lakar__get_project, mcp__lakar__create_project, mcp__lakar__update_project, mcp__lakar__list_phases, mcp__lakar__list_project_phases, mcp__lakar__create_phase, mcp__lakar__update_phase, mcp__lakar__list_milestones, mcp__lakar__create_milestone, mcp__lakar__update_milestone, mcp__lakar__create_milestone_task, mcp__lakar__list_tasks, mcp__lakar__create_task, mcp__lakar__update_task, mcp__lakar__list_labels, mcp__lakar__create_label, mcp__lakar__assign_label_to_task, mcp__notetask__list_workspaces, mcp__notetask__list_projects, mcp__notetask__get_project, mcp__notetask__create_project, mcp__notetask__list_phases, mcp__notetask__create_phase, mcp__notetask__list_milestones, mcp__notetask__create_milestone, mcp__notetask__create_task, mcp__notetask__list_tasks, mcp__notetask__list_labels, mcp__notetask__create_label, mcp__notetask__assign_label_to_task, mcp__cairn__get_current_user, mcp__cairn__list_workspaces, mcp__cairn__list_projects, mcp__cairn__create_project, mcp__cairn__create_project_structure, mcp__cairn__list_labels, mcp__pal__planner
---

Create the project-management phases, milestones, and tasks from the planning documents (in Lakar, Note&Task or Cairn, per project config).

### Project management provider

Resolve the PM provider with the `zao:pm-provider` skill (Skill tool; it ships with the zao
plugin) before the first PM call, and use its mapping (`pm-mapping.md`) for every PM call below.
Steps name the Lakar tool; for `notetask` use the mapped equivalent. Lakar and Note&Task build
the structure row by row; **Cairn** builds it in one `create_project_structure` call (dry run,
approvals, then the real call), described under **Cairn flow** below.

## Relevant MCP Tools
- **PM provider** (Lakar, Note&Task or Cairn): clients or workspaces, projects, phases, milestones, tasks, labels
- **PAL Planner**: structure the breakdown

## Hierarchy

```
Lakar:      Client    → Project → Phase → Milestone → Task
Note&Task:  Workspace → Project → Phase → Milestone → Task
Cairn:      Workspace → Project → Phase → Milestone → Task
```

Use every level. Tasks go inside milestones, milestones inside phases, phases inside a project, project inside a client (Lakar) or workspace (Note&Task, Cairn).

## Prerequisites Check

1. **All planning docs exist**
   - `docs/PRD.md`, `docs/BRAND_GUIDE.md`, `docs/TESTING_STRATEGY.md`
   - Any missing → "All planning docs must be created first. Run `/fra:status` to see what's missing."

2. **Read `.claude/project.yaml`** for `user.mode`, `project.name`, `project.type`, `git.default_branch`, and the resolved provider + statuses (from the `zao:pm-provider` skill). For Cairn also `project_management.workspace` and `project_management.project_identifier`.

3. **Read all three docs** — extract:
   - From PRD: features (core + nice-to-have), technical considerations, priorities, success metrics, and each feature's heading anchor (for `docRefs`)
   - From Brand Guide: visual/UX requirements, accessibility targets
   - From Testing Strategy: test flows, coverage expectations, E2E critical flows

## Setup Process

### Cairn flow

For `provider: cairn`, nothing is created row by row. The order is:

1. Step 1 and Step 2 (workspace and project; nothing is created yet).
2. Plan everything first: Step 3 (phases), Step 5 (milestones per phase) and Step 8 (tasks per
   milestone), **without** creating anything and without asking for approval yet.
3. Step C1: build one `create_project_structure` payload.
4. Step C2: dry run, `create_project_structure {…, dryRun: true}`.
5. Step C3: the approval gates (phases, milestones per phase, tasks per milestone), shown with the
   dry-run counts and warnings. If the user changes anything, rebuild the payload and dry-run again.
6. Step C4: the same payload without `dryRun`, **once**.
7. Step 12: summary.

Steps 4, 6, 7, 9 and 10 (per-row creates, label creation and assignment by UUID) do not apply to
Cairn.

### Step 1: Select the owning scope

- **Lakar:** `mcp__lakar__list_clients` → ask which client should own the project (or stop and
  direct the user to create one in the Lakar UI if none exist). Record `client_id`.
- **Note&Task:** there are no clients. Skip client selection. If a workspace is needed later for
  labels, use `project_management.workspace` from config (resolve via
  `mcp__notetask__list_workspaces` if unset).
- **Cairn:** there are no clients. The workspace is `project_management.workspace`, passed as-is
  (slug, key, name or UUID; no lookup needed). If it is empty: `mcp__cairn__list_workspaces {}`;
  use the only one, or ask which when there are several, and tell the user to save its slug as
  `project_management.workspace` in `.claude/project.yaml`.

### Step 2: Select or create the project

- `mcp__lakar__list_projects` → filter to the chosen client. Show.
- Ask: "Use an existing project or create a new one?" + list + "Create new project".
- Create path:
  - **Lakar:** `mcp__lakar__create_project { client_id, name: project.name, description: project.description }`. Store the returned `project_id`.
  - **Note&Task:** `mcp__notetask__create_project { name: project.name, identifier: project_management.project_identifier }`. Store the returned project id and identifier.
- **Cairn:** `mcp__cairn__list_projects { workspace: <WS> }` and match `identifier` against
  `project_management.project_identifier`. Don't ask and don't create anything here: whether the
  project exists or not, the structure call in Step C1 carries the project, which Cairn matches by
  identifier (and creates when missing). Get the repo with
  `gh repo view --json nameWithOwner -q .nameWithOwner`. If the identifier is empty, ask for one
  (1–6 capitals/digits starting with a letter, e.g. `QAA`) and tell the user to save it as
  `project_management.project_identifier`.

### Step 3: Plan the phase structure

Use `mcp__pal__planner` (at least 3 steps) to propose 3–5 dev phases based on the PRD. Typical phases:

1. **Foundation** — project setup, tooling, baseline architecture
2. **Core Features** — the must-have PRD features
3. **Polish & Edge Cases** — error states, accessibility, empty states
4. **Integration & Testing** — end-to-end integration, test strategy implementation

Adjust to `project.type` (e.g. for an API: Foundation / Core Endpoints / Auth & Hardening / Integration Tests).

Present the proposed phases to the user; only proceed after approval. (**Cairn:** defer this
approval to Step C3.)

### Step 4: Create phases

For each approved phase:
- `mcp__lakar__list_phases` with `{ project_id }` → check for duplicates.
- `mcp__lakar__create_phase` with `{ project_id, name, position }` if absent.
- Store the returned `phase_id` for Step 5.

### Step 5: Plan milestones per phase

For each phase, derive milestones from the PRD (grouping related features into meaningful deliverables). Example for a web-app "Core Features" phase:

- `Auth` — signup, login, password reset
- `Dashboard` — primary user view
- `Settings` — profile + preferences

For each phase, present the proposed milestones and only proceed after approval:

> "For phase **{phase}**, proposed milestones: {list}. Adjust?"

(**Cairn:** defer this approval to Step C3, and give each milestone a one-sentence `goal`, a
`definitionOfDone`, and a `verifyScope`: what the end-of-milestone full suite and E2E tests must
cover, taken from the Testing Strategy's critical flows. A milestone is the unit of
`/zao:run-milestone`.)

### Step 6: Create milestones

For each approved milestone:
- `mcp__lakar__list_milestones` with `{ phase_id }` → avoid duplicates.
- `mcp__lakar__create_milestone` with `{ phase_id, name, position, target_date (optional) }`.

### Step 7: Create labels (one-time)

Note&Task `create_label` requires `workspaceId` — use the resolved workspace.

`mcp__lakar__list_labels` → check what exists. Create only the missing ones via `mcp__lakar__create_label`. Recommended defaults — **only create if they don't already exist**:

- **Area labels** (derive from PRD tech considerations): `area:frontend`, `area:backend`, `area:database`, `area:infrastructure`, plus any project-specific areas.
- **Priority labels** (optional — Lakar tasks already have story points, but labels help at-a-glance filtering): `priority:critical`, `priority:high`, `priority:medium`, `priority:low`.

> **Don't** create `type:*` labels — Lakar tasks already have a native `type` field (`Story` / `Bug` / `Feature` / `Chore` / `Technical Debt`). Use that instead.

(**Cairn:** skip this step. List the labels in the payload's top-level `labels` and on each task;
missing labels are created by the structure call. `mcp__cairn__list_labels { workspace: <WS> }`
shows what already exists, if useful. Cairn tasks also have native `taskType` and `priority`, so
don't create `type:*` labels there either.)

### Step 8: Plan tasks per milestone

Use `mcp__pal__planner` to break each milestone into concrete tasks. For each task, derive:

- **Title** — action-oriented, specific (e.g. "Implement login form validation")
- **Type** (native field) — `Story`, `Bug`, `Feature`, `Chore`, or `Technical Debt`
- **Story points** — Fibonacci (`"1"`, `"2"`, `"3"`, `"5"`, `"8"`, `"13"`) per the estimation table below
- **Description** — use this template:

  ```markdown
  ## Overview
  {What needs to be built, from the PRD}

  ## Technical Details
  - Location: {where the code should live}
  - Key dependencies: {what this relies on}
  - Patterns to follow: {reference Brand Guide sections where applicable}

  ## Acceptance Criteria
  - [ ] {specific, testable criterion}
  - [ ] {specific, testable criterion}
  - [ ] Unit tests written and passing
  - [ ] Matches Brand Guide specs (if UI)
  - [ ] Accessibility requirements met (if UI)

  ## Testing Notes
  {from Testing Strategy — what tests are needed for this task}

  ## Related
  - PRD feature: {reference}
  - Brand Guide: {sections, if applicable}
  ```

- **Labels** (by UUID) — `area:*` plus optional `priority:*`
- **Status** — default to `{statuses.todo}` from project config (default `"Todo"`)
- **Milestone** — the milestone this task belongs to
- **Cairn only:** also derive **priority** (`urgent`, `high`, `medium`, `low`, `none`), the tasks
  it **depends on** within the plan, and the PRD feature anchor it implements (for `docRefs`).

### Step 9: Present proposed tasks per milestone for approval

For each milestone, list task titles + one-line summaries + proposed story points. Ask:
> "For milestone **{name}**: these {N} tasks look right? Add / remove / rename?"

Only proceed after explicit approval. (**Cairn:** defer this approval to Step C3.)

### Step 10: Create tasks

For each approved task, call `mcp__lakar__create_milestone_task` (creates a task directly inside a milestone) — or `mcp__lakar__create_task` with `milestone_id` set — with:

- `title`
- `description` (full markdown body from the template)
- `type` (`Story` / `Bug` / `Feature` / `Chore` / `Technical Debt`)
- `story_points` (`"1"`–`"13"`)
- `status: "{statuses.todo}"`
- `milestone_id`

Then, for each label that applies to the task, call `mcp__lakar__assign_label_to_task` with `{ task_id, label_id }`.

Record the returned `{ task.id, task.code }` for the final report.

### Step C1 (Cairn): Build the structure payload

Build **one** payload for `mcp__cairn__create_project_structure`:

```json
{
  "project": {
    "workspace": "<WS>",
    "name": "<project.name>",
    "identifier": "<PROJ>",
    "description": "<project.description>",
    "repo": "<owner/name from gh repo view>",
    "devBranch": "<git.default_branch>",
    "docPaths": { "prd": "docs/PRD.md", "brand": "docs/BRAND_GUIDE.md", "testing": "docs/TESTING_STRATEGY.md" }
  },
  "labels": [{ "name": "area:frontend" }, { "name": "priority:high" }],
  "phases": [{
    "name": "Core Features",
    "description": "…",
    "milestones": [{
      "name": "Auth",
      "goal": "Users can sign up, log in and reset their password",
      "definitionOfDone": "…",
      "verifyScope": "E2E: signup, login, password reset (TESTING_STRATEGY critical flows 1–3)",
      "tasks": [{
        "key": "implement-login-form-validation",
        "title": "Implement login form validation",
        "description": "## Overview\n…\n## Technical Details\n…\n## Testing Notes\n…\n## Related\n…",
        "acceptanceCriteria": ["Invalid emails show an inline error", "Unit tests written and passing"],
        "taskType": "feature",
        "priority": "high",
        "storyPoints": 3,
        "status": "todo",
        "labels": ["area:frontend", "priority:high"],
        "dependsOn": ["auth-api-endpoints"],
        "docRefs": ["docs/PRD.md#authentication"]
      }]
    }]
  }]
}
```

Rules:
- `project` is always sent, whether or not the project exists: Cairn matches it by `identifier`
  and creates it when missing (updating any changed `repo`, `devBranch`, `docPaths`, description).
- Each task's `key` is its slugified title (lowercase, `[a-z0-9-]`, at most 64 characters, unique
  in the payload). `dependsOn` takes payload keys (or existing task codes).
- `description` is the Step 8 template **without** the `## Acceptance Criteria` checklist: the
  criteria move into `acceptanceCriteria[]` as plain testable statements (including "Unit tests
  written and passing", "Matches Brand Guide specs" and "Accessibility requirements met" where
  they apply). `/zao:` commands and milestone runs read them from there.
- `taskType`: Story or Feature → `feature`, Bug → `bug`, Chore → `chore`, Technical Debt →
  `tech_debt`. `storyPoints` is a number (1, 2, 3, 5, 8). `status` is `todo`.
- `labels` on each task are names (`area:*`, `priority:*`); the top-level `labels` list ensures
  they exist in the workspace. No separate label calls.
- `docRefs` point at the PRD feature anchors the task implements (`docs/PRD.md#<anchor>`), so
  `/fra:update-prd` can find affected tasks later.
- Limits per call: 10 phases, 30 milestones, 300 tasks. Above that, stop and suggest splitting
  the plan (for example one call per phase, each with the same `project`).

### Step C2 (Cairn): Dry run

Call `mcp__cairn__create_project_structure { …payload, dryRun: true }`. It writes nothing.
Show the `counts` (created / updated / unchanged per level), the `refs` the items will get
(`(new)` for new ones), and every `warnings` entry (for example a task matched by title in a
different container, or a readiness gap). If the call fails (`invalid_argument` for a cycle, a
bad `dependsOn` or a limit; `hierarchy_violation`), fix the payload and dry-run again.

### Step C3 (Cairn): Approval gates

Run the same three approvals as the other providers, with the dry-run output beside them:

1. The phases (Step 3).
2. For each phase, its milestones with goal and verify scope (Step 5).
3. For each milestone, its tasks: title, one-line summary, points, priority, dependencies and
   acceptance criteria (Step 9).

Only proceed after explicit approval of all three. If the user adds, removes or renames
anything, rebuild the payload and repeat Step C2 before asking again.

### Step C4 (Cairn): Create the structure

Send the **same** payload once more without `dryRun`:
`mcp__cairn__create_project_structure { …payload }`. It is all or nothing, and re-sending the
same payload creates nothing new (items match by name, tasks by `key`), so a retry after a
network failure is safe. Keep `refs` (phase, milestone and task codes) for the summary.

### Step 11: Estimation guidelines

| Points | Meaning | Example |
|--------|---------|---------|
| 1  | Trivial, < 1 hour       | Add a config value, fix typo |
| 2  | Simple, half day        | Small component, basic endpoint |
| 3  | Straightforward, ~1 day | Standard feature |
| 5  | Medium, 2–3 days        | Complex component, multi-step flow |
| 8  | Complex, ~1 week        | Major feature |
| 13 | Very complex            | Consider splitting before creating |

Tasks estimated at 13 points should be split before creation — ask the user to do this, or suggest a split.

### Step 12: Summary report

```
**Project management structure populated** (provider: {provider})

Client:   {client name}   (Lakar only; Cairn shows Workspace: {workspace} instead)
Project:  {project name}  ({identifier}, Note&Task and Cairn)

Phases:   {N}
  - {phase name} ({phase ref, Cairn}) — {M} milestones
    - {milestone} ({milestone ref, Cairn}) — {K} tasks, {P} total points

Labels created: {list}

Totals: {N} phases, {M} milestones, {K} tasks, {P} story points.

Next steps:
1. Review the tasks in your PM app (Lakar, Note&Task or Cairn)
2. Adjust priorities / assignees as needed
3. Start the first task: `/zao:begin-task {first task code}`
4. (Cairn) Or run a whole milestone autonomously: `/zao:run-milestone {first milestone ref} --dry-run`
```

For Cairn, take the refs and codes from the structure call's `refs` (`phases`, `milestones`,
`tasks`) and the totals from its `counts`.

## Error Handling

- **No clients exist** (Lakar): stop, direct user to create one in the Lakar UI.
- **Phase / milestone / task creation fails mid-way** (Lakar, Note&Task): stop at the failing row, report what was created, don't retry blindly.
- **Structure call fails** (Cairn): nothing was created (the call is all or nothing). Show the error, fix the payload, dry-run again. On `internal` or a transport error, retry once with the identical payload.
- **Duplicate phase or milestone**: reuse it, don't create a duplicate (Cairn matches by name automatically).
- **PAL Planner unavailable**: fall back to a simpler breakdown derived directly from the PRD feature list.

## Important

- Respect the hierarchy: client or workspace → project → phase → milestone → task. Don't create orphan tasks.
- Every task must carry **Acceptance Criteria** — `/zao:` commands parse them. Lakar and Note&Task: a checklist in the description. Cairn: the `acceptanceCriteria` list (not in the description).
- Use the native type field (Lakar `type`, Note&Task and Cairn `taskType`) instead of `type:*` labels.
- Use native story points instead of `estimate:*` labels.
- Don't create tasks with 13 story points — split first.
- Reference PRD / Brand Guide / Testing Strategy in task descriptions (Cairn: also `docRefs`).
- Cairn: always dry-run first and send the identical payload for the real call.
