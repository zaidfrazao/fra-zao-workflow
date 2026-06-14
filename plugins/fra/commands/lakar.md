---
description: Create a Lakar project structure (phases, milestones, tasks) from the PRD, Brand Guide, and Testing Strategy
allowed-tools: AskUserQuestion, Read, mcp__lakar__list_clients, mcp__lakar__list_projects, mcp__lakar__get_project, mcp__lakar__create_project, mcp__lakar__update_project, mcp__lakar__list_phases, mcp__lakar__create_phase, mcp__lakar__update_phase, mcp__lakar__list_milestones, mcp__lakar__create_milestone, mcp__lakar__update_milestone, mcp__lakar__create_milestone_task, mcp__lakar__list_tasks, mcp__lakar__create_task, mcp__lakar__update_task, mcp__lakar__list_labels, mcp__lakar__create_label, mcp__lakar__assign_label_to_task, mcp__pal__planner
---

Create Lakar phases, milestones, and tasks from the planning documents.

## Relevant MCP Tools
- **Lakar**: clients, projects, phases, milestones, tasks, labels
- **PAL Planner**: structure the breakdown

## Lakar Hierarchy

```
Client → Project → Phase → Milestone → Task
```

Use all five levels. Tasks go inside milestones, milestones inside phases, phases inside a project, project inside a client.

## Prerequisites Check

1. **All planning docs exist**
   - `docs/PRD.md`, `docs/BRAND_GUIDE.md`, `docs/TESTING_STRATEGY.md`
   - Any missing → "All planning docs must be created first. Run `/fra:status` to see what's missing."

2. **Read `.claude/project.yaml`** for `user.mode`, `project.name`, `project.type`, and `lakar.statuses.*`.

3. **Read all three docs** — extract:
   - From PRD: features (core + nice-to-have), technical considerations, priorities, success metrics
   - From Brand Guide: visual/UX requirements, accessibility targets
   - From Testing Strategy: test flows, coverage expectations

## Setup Process

### Step 1: Select or create the client

- `mcp__lakar__list_clients` → show existing clients.
- Ask via `AskUserQuestion`: "Which client should own this project?" (options: each existing client + "Create new client").
- If creating new: delegate to the Lakar UI — Lakar's MCP supports creating clients, but for structural work it's cleaner to have the user set that up first. Stop with instructions if the user picks "Create new".

### Step 2: Select or create the project

- `mcp__lakar__list_projects` → filter to the chosen client. Show.
- Ask: "Use an existing project or create a new one?" + list + "Create new project".
- Create path: `mcp__lakar__create_project` with `{ client_id, name: project.name, description: project.description }`.
- Store the returned `project_id`.

### Step 3: Plan the phase structure

Use `mcp__pal__planner` (at least 3 steps) to propose 3–5 dev phases based on the PRD. Typical phases:

1. **Foundation** — project setup, tooling, baseline architecture
2. **Core Features** — the must-have PRD features
3. **Polish & Edge Cases** — error states, accessibility, empty states
4. **Integration & Testing** — end-to-end integration, test strategy implementation

Adjust to `project.type` (e.g. for an API: Foundation / Core Endpoints / Auth & Hardening / Integration Tests).

Present the proposed phases to the user; only proceed after approval.

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

### Step 6: Create milestones

For each approved milestone:
- `mcp__lakar__list_milestones` with `{ phase_id }` → avoid duplicates.
- `mcp__lakar__create_milestone` with `{ phase_id, name, position, target_date (optional) }`.

### Step 7: Create labels (one-time)

`mcp__lakar__list_labels` → check what exists. Create only the missing ones via `mcp__lakar__create_label`. Recommended defaults — **only create if they don't already exist**:

- **Area labels** (derive from PRD tech considerations): `area:frontend`, `area:backend`, `area:database`, `area:infrastructure`, plus any project-specific areas.
- **Priority labels** (optional — Lakar tasks already have story points, but labels help at-a-glance filtering): `priority:critical`, `priority:high`, `priority:medium`, `priority:low`.

> **Don't** create `type:*` labels — Lakar tasks already have a native `type` field (`Story` / `Bug` / `Feature` / `Chore` / `Technical Debt`). Use that instead.

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
- **Status** — default to `{lakar.statuses.todo}` from project config (default `"Todo"`)
- **Milestone** — the milestone this task belongs to

### Step 9: Present proposed tasks per milestone for approval

For each milestone, list task titles + one-line summaries + proposed story points. Ask:
> "For milestone **{name}**: these {N} tasks look right? Add / remove / rename?"

Only proceed after explicit approval.

### Step 10: Create tasks

For each approved task, call `mcp__lakar__create_milestone_task` (creates a task directly inside a milestone) — or `mcp__lakar__create_task` with `milestone_id` set — with:

- `title`
- `description` (full markdown body from the template)
- `type` (`Story` / `Bug` / `Feature` / `Chore` / `Technical Debt`)
- `story_points` (`"1"`–`"13"`)
- `status: "{lakar.statuses.todo}"`
- `milestone_id`

Then, for each label that applies to the task, call `mcp__lakar__assign_label_to_task` with `{ task_id, label_id }`.

Record the returned `{ task.id, task.code }` for the final report.

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
**Lakar project populated**

Client:   {client name}
Project:  {project name}

Phases:   {N}
  - {phase name} — {M} milestones
    - {milestone} — {K} tasks, {P} total points

Labels created: {list}

Totals: {N} phases, {M} milestones, {K} tasks, {P} story points.

Next steps:
1. Review the tasks in Lakar
2. Adjust priorities / assignees as needed
3. Start the first task: `/zao:begin-task {first task code}`
```

## Error Handling

- **No clients exist**: stop, direct user to create one in the Lakar UI.
- **Phase / milestone / task creation fails mid-way**: stop at the failing row, report what was created, don't retry blindly.
- **Duplicate phase or milestone**: reuse it, don't create a duplicate.
- **PAL Planner unavailable**: fall back to a simpler breakdown derived directly from the PRD feature list.

## Important

- Respect the hierarchy: client → project → phase → milestone → task. Don't create orphan tasks.
- Every task description must include an **Acceptance Criteria** checklist — `/zao:` commands parse it.
- Use Lakar's native `type` field instead of `type:*` labels.
- Use Lakar's native `story_points` instead of `estimate:*` labels.
- Don't create tasks with 13 story points — split first.
- Reference PRD / Brand Guide / Testing Strategy in task descriptions.
