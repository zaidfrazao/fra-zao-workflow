---
description: Learn about the development workflow and see where you currently are in the process
allowed-tools: Skill, mcp__lakar__get_task, mcp__lakar__list_tasks, Bash, mcp__notetask__get_task, mcp__notetask__list_tasks, mcp__cairn__get_task_context, mcp__cairn__next_task, mcp__cairn__get_milestone_run
---

Explain the /fra/zao development workflow to the user and show where they currently are if mid-task.

### Project management provider

Resolve the PM provider with the `zao:pm-provider` skill (Skill tool) before the first PM call,
and use its mapping (`pm-mapping.md`) for every PM call below. Steps name the Lakar tool; for
`notetask` and `cairn` use the mapped equivalent. Where Cairn behaves differently, the step says
so under **Cairn:**. Lakar and Note&Task behaviour is unchanged.

## Steps

1. **Detect current state**
   - Read `.claude/project.yaml` for `git.default_branch` and `git.branch_prefixes`
   - Check if on a task branch with the `zao:pm-provider` skill's branch rule (Lakar and
     Note&Task: strip any configured `git.branch_prefixes` value and read the task code, e.g.
     `feature/TSK-123-some-title` → `TSK-123`; the default branch is never a task branch)
   - If a task is detected, fetch its current status using `mcp__lakar__get_task`
   - **Cairn:** `mcp__cairn__get_task_context { branch: "<current branch>" }` replaces the
     parsing and the fetch; keep its `status`, `activeRun` and `suggestedNextCommand`. On the
     default branch, `mcp__cairn__next_task { projectIdentifier: <PROJ> }` gives the next ready
     task and `mcp__cairn__get_milestone_run { projectIdentifier: <PROJ> }` any active run.
   - Check if a PR exists for the current branch using `gh pr view --json state,url 2>/dev/null`

2. **Present the workflow**

   Explain the workflow in simple, non-technical terms:

   ---

   **The /fra/zao Development Workflow**

   Here's how we work on tasks from start to finish:

   1. **Start a task** (`/zao:begin-task TSK-XXX`)
      - Fetches the task details from your project-management app
      - Creates a plan for how to build it
      - You review and approve the plan before any coding begins

   2. **Build it** (`/zao:implement-task`)
      - Executes the approved plan
      - Writes the actual code

   3. **Review and refine** (repeat as needed)
      - You review what was built
      - `/zao:fix-issue <description>` - Fix any bugs you find
      - `/zao:adjust-feature <description>` - Request tweaks or changes

   4. **Test it** (`/zao:test-task`)
      - Runs automated checks (code quality, visual tests)
      - Reports any issues in plain language

   5. **Submit for review** (`/zao:submit-task`)
      - Creates a pull request for code review
      - Updates the task status to "In Review"
      - Adds technical notes for the team lead if needed

   6. **Finish up** (`/zao:finish-task`)
      - After the PR is approved, this merges the work
      - Cleans everything up
      - Marks the task as complete

   **Other helpful commands:**
   - `/zao:check-status` - See where things stand and what to do next
   - `/zao:pause-task` - Save your progress to continue later
   - `/zao:resume-task` - Pick up where you left off
   - `/zao:cancel-task` - Abandon the current task if needed

   **Milestone mode (Cairn only):**
   - `/zao:run-milestone <milestone>` (e.g. `/zao:run-milestone QAA-M3`) works through every
     task of a Cairn milestone on its own. It creates a milestone branch from the dev branch,
     runs each task through this same lifecycle on its own branch off the milestone branch,
     with only the quick checks (lint, typecheck, unit tests) per task. At the end it runs the
     full test suite, including E2E, once, fixes what fails, and then merges the milestone into
     the dev branch. It asks you only at declared checkpoints (gates), in Cairn or in chat.
   - Mention this section only when the provider is `cairn`; otherwise say milestone mode needs
     the Cairn provider.

   ---

3. **Show current position (if applicable)**

   If the user is mid-task, highlight where they are:

   - If on the default branch with no active task:
     > "You're not currently working on a task. To start, run `/zao:begin-task TSK-XXX` with your task code from {provider}."
     - **Cairn:** name the next ready task from `next_task` ("Next up: `/zao:begin-task QAA-14`"),
       and if a milestone run is active, its ref, state and "`/zao:run-milestone --status` for details".

   - If on a task branch with status "In Progress" and no PR:
     > "You're currently working on **TSK-XXX: {title}**. You're in the build/refine phase. When ready, run `/zao:test-task` to check your work, or `/zao:submit-task` to submit for review."

   - If on a task branch with status "In Review" and PR exists:
     > "You're on **TSK-XXX: {title}** which is in review. PR: {url}. Once approved, run `/zao:finish-task` to merge and complete."

   - If the task is paused/blocked:
     > "Task **TSK-XXX: {title}** is paused. Run `/zao:resume-task` to continue where you left off."

   - **Cairn:** place the user in the workflow from `suggestedNextCommand` (for example
     `/zao:implement-task` → building, `/zao:test-task` → ready to test, `/zao:finish-task` →
     in review). If `activeRun` shows the task queued or in flight in a milestone run, say the
     run is handling it and point to `/zao:run-milestone --status`.

## Important

- Use friendly, non-technical language throughout
- Don't assume the user knows git, PRs, or branches - explain in terms of "tasks" and "work"
- Always end with a clear suggestion of what they can do next
