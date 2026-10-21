---
description: See your progress through the project setup phases
allowed-tools: Bash, Read, Skill, mcp__lakar__list_projects, mcp__lakar__list_clients, mcp__notetask__list_projects, mcp__cairn__list_projects, mcp__cairn__list_milestones
---

Show the current status of project setup and what needs to be done next.

## Steps

1. **Check which docs exist**

   Look for these files in the `docs/` directory:
   - `docs/PRD.md`
   - `docs/BRAND_GUIDE.md`
   - `docs/TESTING_STRATEGY.md`

2. **Check the project-management structure**

   - Resolve the PM provider with the `zao:pm-provider` skill (Skill tool; it ships with the zao
     plugin) before the first PM call, and use its mapping (`pm-mapping.md`) for every PM call
     below.
   - **Lakar:** `mcp__lakar__list_clients` + `mcp__lakar__list_projects`.
   - **Note&Task:** `mcp__notetask__list_projects` (match on `project_management.project_identifier`).
   - **Cairn:** `mcp__cairn__list_projects { workspace: <project_management.workspace> }`, matched
     on `identifier` = `project_management.project_identifier`. If the project exists, show its
     milestone progress with `mcp__cairn__list_milestones { projectIdentifier: <identifier> }`:
     for each milestone its ref, name, state, progress (tasks and points done of planned) and any
     active milestone run (`activeRun.ref` and state).

3. **Present status report**

   ---

   **Project Setup Status**

   | Phase | Status | Command |
   |-------|--------|---------|
   | Product Requirements | {Done/Not started} | `/fra:prd` |
   | Brand Guide | {Done/Not started/Waiting on PRD} | `/fra:brand` |
   | Testing Strategy | {Done/Not started/Waiting on PRD + Brand} | `/fra:testing` |
   | PM Structure | {Done/Not started/Waiting on all docs} | `/fra:setup-pm` |

   **Milestones** (Cairn only, when the project exists)

   | Milestone | State | Progress | Active run |
   |-----------|-------|----------|------------|
   | {ref} {name} | {state} | {tasksDone}/{tasksTotal} tasks · {pointsDone}/{pointsPlanned} pts | {run ref and state, or —} |

   ---

4. **Provide next step recommendation**

   Based on what's missing, recommend the next command:

   - If no PRD: "Start by defining what you're building. Run `/fra:prd`"
   - If PRD exists but no brand guide: "Next, define the visual and UX approach. Run `/fra:brand`"
   - If PRD + brand exist but no testing: "Next, the testing strategy will be generated. Run `/fra:testing`"
   - If all docs exist but no PM structure: "All planning docs are ready! Run `/fra:setup-pm` to create your project-management structure"
   - If everything done: "Project setup is complete! You can update any doc with `/fra:update-prd`, `/fra:update-brand`, or `/fra:update-testing`"
     (Cairn: also suggest `/zao:run-milestone <next milestone ref> --dry-run` for the first milestone that is not completed, or `/zao:run-milestone --status` if a run is active.)

5. **Show doc summaries (if they exist)**

   For each existing doc, show a brief summary:
   - PRD: Product name, vision statement, number of features defined
   - Brand Guide: Design system summary, key patterns
   - Testing Strategy: Types of testing planned

## Important

- This command is informational only - it doesn't create or modify anything
- Use friendly, clear language
- Always end with a specific next action
