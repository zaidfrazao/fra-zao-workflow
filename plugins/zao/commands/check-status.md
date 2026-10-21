---
description: See where things stand with your current task and what to do next
allowed-tools: Skill, mcp__lakar__get_task, Bash, mcp__notetask__get_task, mcp__cairn__get_task_context, mcp__cairn__next_task, mcp__cairn__get_milestone_run
---

Check the current state of the user's work and provide clear guidance on what to do next.

### Project management provider

Resolve the PM provider with the `zao:pm-provider` skill (Skill tool) before the first PM call,
and use its mapping (`pm-mapping.md`) for every PM call below. Steps name the Lakar tool; for
`notetask` and `cairn` use the mapped equivalent. Where Cairn behaves differently, the step says
so under **Cairn:**. Lakar and Note&Task behaviour is unchanged.

## Relevant MCP Tools
- **PM provider** (Lakar, Note&Task or Cairn): check task status and details; Cairn also
  suggests the next command and shows any active milestone run
- **Git**: Determine branch state, uncommitted changes, PR status

## Steps

1. **Gather current state**

   Run these checks:

   a. **Current branch**
      ```bash
      git branch --show-current
      ```
      Read `.claude/project.yaml` for `git.default_branch` and `git.branch_prefixes`.

   b. **Uncommitted changes**
      ```bash
      git status --porcelain
      ```

   c. **Check if on a task branch**
      - Use the `zao:pm-provider` skill's branch rule: for Lakar and Note&Task, strip any
        configured `git.branch_prefixes` value (`feature/`, `fix/`, `hotfix/`, `chore/`, …) and
        read the task code (`{prefix}TSK-XXX-*` → `TSK-XXX`)
      - **Cairn:** `mcp__cairn__get_task_context { branch: "<current branch>" }` instead of
        parsing; `not_found` means this is not a task branch

   d. **If a task is detected, fetch its status**
      - Use `mcp__lakar__get_task` to get current state, title, description
      - **Cairn:** the `get_task_context` result already has the status, plan step statuses,
        latest test run, PR link, `paused`, `activeRun` and `suggestedNextCommand`

   e. **Check for existing PR**
      ```bash
      gh pr view --json state,url,title,reviewDecision 2>/dev/null || echo "NO_PR"
      ```

   f. **Check for remote branch**
      ```bash
      git ls-remote --heads origin $(git branch --show-current) 2>/dev/null
      ```

   g. **Cairn, on `{git.default_branch}` (no task branch):**
      - `mcp__cairn__next_task { projectIdentifier: <PROJ> }` → the next ready task and its
        `suggestedCommand`
      - `mcp__cairn__get_milestone_run { projectIdentifier: <PROJ> }` → the project's active
        milestone run, if any (`run: null` means none)

2. **Diagnose and report**

   Based on the gathered information, present a clear status report:

   ---

   **Current Status**

   - **Task**: {TSK-XXX: Title} or "No active task"
   - **Status**: {status in the PM app} or "N/A"
   - **Progress**: {Description of where they are}
   - **Unsaved changes**: {Yes/No - if yes, list changed files in simple terms}

   ---

   **Cairn:** add, when present:
   - **Plan**: steps done out of total; **Acceptance criteria**: `coverage` done out of total;
     **Latest test run**: its ref and status
   - **Milestone run** (from `get_milestone_run`): run ref, state, the current task and step,
     counters ("4 of 9 integrated"), any open gate, and the heartbeat: "last heard 12 s ago"
     while live, "stale · 18 min" when `run.lease.stale`, "waiting for you" when
     `run.lease.waitingOnHuman`. Point to `/zao:run-milestone --status` for the full picture.

3. **Provide next step recommendation**

   Based on the state, recommend ONE clear action:

   | State | Recommendation |
   |-------|----------------|
   | On the default branch, no changes | "Ready to start! Run `/zao:begin-task TSK-XXX` with your task code." |
   | On the default branch, with changes | "You have unsaved work on the `{git.default_branch}` branch. This is unusual - did you mean to start a task first?" |
   | On task branch, status "Todo" | "Task not started properly. Run `/zao:begin-task TSK-XXX` to set it up correctly." |
   | On task branch, status "In Progress", no changes | "Ready to build! Run `/zao:implement-task` to start coding." |
   | On task branch, status "In Progress", with changes, no PR | "You have work in progress. Options: `/zao:test-task` to check it, `/zao:submit-task` when ready for review." |
   | On task branch, status "In Review", PR open | "Waiting for review on PR: {url}. Once approved, run `/zao:finish-task` to complete." |
   | On task branch, status "In Review", PR approved | "PR is approved! Run `/zao:finish-task` to merge and complete the task." |
   | On task branch, status "In Review", PR has requested changes | "The PR needs changes. Review the feedback, then use `/zao:fix-issue` to address it." |
   | On task branch, status "Paused" or similar | "This task is paused. Run `/zao:resume-task` to continue." |
   | On task branch, status "Done" | "This task is already complete! Switch to `{git.default_branch}` and start a new task." |

   **Cairn:** combine `suggestedNextCommand` with the local git state instead of using the
   status rows above:
   - The task is `queued` or in flight in a milestone run (`activeRun.entryState`): "The
     milestone run {activeRun.runId} is handling this task; don't work on it by hand. Check the
     run with `/zao:run-milestone --status`."
   - Uncommitted changes override the suggestion when it would lose them: recommend saving
     (`/zao:save`) or `/zao:test-task` first.
   - An open PR with requested changes overrides it with `/zao:fix-issue`; an approved open PR
     with `/zao:finish-task`.
   - Otherwise recommend `suggestedNextCommand` as-is (e.g. `/zao:implement-task`,
     `/zao:fix-issue`, `/zao:submit-task`).
   - On the default branch: recommend `next_task`'s `suggestedCommand` (e.g.
     `/zao:begin-task QAA-14`); if a milestone run is active and needs you (open gate or stale),
     recommend `/zao:run-milestone --status` instead.

4. **Handle error states**

   If something seems wrong, explain in plain terms:

   - **Detached HEAD**: "Something's off with the code state. Let me help fix this..." (offer to checkout the correct branch)
   - **Merge conflicts**: "There are conflicts that need resolving. I can help walk you through this."
   - **Can't reach the PM app**: "Couldn't connect to {provider} to check task status. The task code might be wrong, or there might be a connection issue."
   - **Branch doesn't match a task**: "The branch name doesn't match a task in {provider}. You might want to run `/zao:begin-task` to start fresh."

## Important

- Always use simple, non-technical language
- Give exactly ONE recommended next action (not multiple options unless truly ambiguous)
- If something is broken, offer to help fix it rather than just reporting the error
- End with an actionable suggestion
- This command is read-only: it never changes the task, the run or the branches
