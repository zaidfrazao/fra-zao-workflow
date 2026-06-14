---
description: See where things stand with your current task and what to do next
allowed-tools: mcp__lakar__get_task, Bash, mcp__notetask__get_task
---

Check the current state of the user's work and provide clear guidance on what to do next.

### Project management provider

This command supports two PM backends. Resolve which from `.claude/project.yaml`:
- If a `project_management:` block exists, use `project_management.provider` (assume `lakar` if
  that key is absent).
- Else if a legacy `lakar:` block exists, the provider is `lakar` (statuses from
  `lakar.statuses.*`, client from `team.lakar_client`).
- Else default to `lakar`.

Status **values** come from config (`project_management.statuses.*`, or legacy
`lakar.statuses.*`). Wherever a step below names an `mcp__lakar__*` tool, use the resolved
provider's equivalent:

| Operation | Lakar (`provider: lakar`) | Note&Task (`provider: notetask`) |
|---|---|---|
| Fetch task by code | `mcp__lakar__get_task { id: CODE }` | `mcp__notetask__get_task { code: CODE }` |
| Set task status | `mcp__lakar__update_task { id: CODE, status: <value> }` | `mcp__notetask__update_task { code: CODE, phase: <value> }` |
| List tasks by status | `mcp__lakar__list_tasks { status: <value> }` | `mcp__notetask__list_tasks { phase: <value> }` |
| Add comment | `mcp__lakar__create_comment { task_id: CODE, content }` — Lakar also needs `user_id` from `mcp__lakar__get_current_user` | `mcp__notetask__create_comment { code: CODE, content }` — no `user_id` |
| List comments | `mcp__lakar__list_task_comments { task_id: CODE }` | `mcp__notetask__list_task_comments { code: CODE }` |

## Relevant MCP Tools
- **Lakar**: Check task status and details
- **Git**: Determine branch state, uncommitted changes, PR status

## Steps

1. **Gather current state**

   Run these checks:

   a. **Current branch**
      ```bash
      git branch --show-current
      ```

   b. **Uncommitted changes**
      ```bash
      git status --porcelain
      ```

   c. **Check if on a task branch**
      - If branch matches pattern `feature/*`, `bugfix/*`, or `hotfix/*`, extract the Lakar task code
      - Pattern: `{type}/TSK-XXX-*` → extract `TSK-XXX`

   d. **If Lakar task detected, fetch its status**
      - Use `mcp__lakar__get_task` to get current state, title, description

   e. **Check for existing PR**
      ```bash
      gh pr view --json state,url,title,reviewDecision 2>/dev/null || echo "NO_PR"
      ```

   f. **Check for remote branch**
      ```bash
      git ls-remote --heads origin $(git branch --show-current) 2>/dev/null
      ```

2. **Diagnose and report**

   Based on the gathered information, present a clear status report:

   ---

   **Current Status**

   - **Task**: {TSK-XXX: Title} or "No active task"
   - **Status**: {Lakar status} or "N/A"
   - **Progress**: {Description of where they are}
   - **Unsaved changes**: {Yes/No - if yes, list changed files in simple terms}

   ---

3. **Provide next step recommendation**

   Based on the state, recommend ONE clear action:

   | State | Recommendation |
   |-------|----------------|
   | On main/develop, no changes | "Ready to start! Run `/zao:begin-task TSK-XXX` with your task code." |
   | On main/develop, with changes | "You have unsaved work on the main branch. This is unusual - did you mean to start a task first?" |
   | On task branch, Lakar "Todo" | "Task not started properly. Run `/zao:begin-task TSK-XXX` to set it up correctly." |
   | On task branch, Lakar "In Progress", no changes | "Ready to build! Run `/zao:implement-task` to start coding." |
   | On task branch, Lakar "In Progress", with changes, no PR | "You have work in progress. Options: `/zao:test-task` to check it, `/zao:submit-task` when ready for review." |
   | On task branch, Lakar "In Review", PR open | "Waiting for review on PR: {url}. Once approved, run `/zao:finish-task` to complete." |
   | On task branch, Lakar "In Review", PR approved | "PR is approved! Run `/zao:finish-task` to merge and complete the task." |
   | On task branch, Lakar "In Review", PR has requested changes | "The PR needs changes. Review the feedback, then use `/zao:fix-issue` to address it." |
   | On task branch, Lakar "Paused" or similar | "This task is paused. Run `/zao:resume-task` to continue." |
   | On task branch, Lakar "Done" | "This task is already complete! Switch to main and start a new task." |

4. **Handle error states**

   If something seems wrong, explain in plain terms:

   - **Detached HEAD**: "Something's off with the code state. Let me help fix this..." (offer to checkout the correct branch)
   - **Merge conflicts**: "There are conflicts that need resolving. I can help walk you through this."
   - **Can't reach Lakar**: "Couldn't connect to Lakar to check task status. The task code might be wrong, or there might be a connection issue."
   - **Branch doesn't match Lakar task**: "The branch name doesn't match a Lakar task. You might want to run `/zao:begin-task` to start fresh."

## Important

- Always use simple, non-technical language
- Give exactly ONE recommended next action (not multiple options unless truly ambiguous)
- If something is broken, offer to help fix it rather than just reporting the error
- End with an actionable suggestion
