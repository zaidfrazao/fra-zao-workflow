---
description: Save your progress and pause the current task to continue later
allowed-tools: mcp__lakar__get_task, mcp__lakar__update_task, mcp__lakar__create_comment, mcp__lakar__get_current_user, Bash, AskUserQuestion, mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user
---

Pause the current task and save progress for later.

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
- **Lakar**: Update task status, add pause notes documenting progress

## Prerequisites Check

1. **Check current branch**
   - Run `git branch --show-current`
   - If on `main` or `develop`:
     > "You're not on a task branch. There's nothing to pause."
     - Stop execution

2. **Get task context**
   - Parse Lakar task code from branch name
   - Use `mcp__lakar__get_task` to fetch task details

## Pause Process

1. **Ask for pause reason** (optional context)
   - Use `AskUserQuestion`:
     > "Before pausing, is there anything specific you'd like me to note about where you left off? (Optional - you can skip this)"

2. **Save all current work**
   - Check for uncommitted changes: `git status --porcelain`
   - If there are changes:
     ```bash
     git add -A
     git commit -m "wip: pausing task - progress saved"
     ```

3. **Push to remote** (so work isn't lost)
   ```bash
   git push -u origin $(git branch --show-current)
   ```

4. **Analyze current progress**

   Automatically determine what's been done:
   - Review commits on this branch vs main
   - Identify files changed
   - Summarize what's implemented vs what's remaining (based on original task description)

5. **Add pause notes to Lakar**

   Use `mcp__lakar__create_comment` to document the pause:

   > **Task Paused**
   >
   > **Progress so far:**
   > - {List what's been completed}
   >
   > **Remaining work:**
   > - {List what still needs to be done}
   >
   > **Branch:** `{branch-name}`
   >
   > {User's optional notes if provided}
   >
   > ---
   > *To resume: `/zao:resume-task`*

6. **Update Lakar status** (if there's a "Paused" or "On Hold" status)
   - Use `mcp__lakar__update_task` to update status if applicable
   - If no paused status exists, leave as "In Progress" (the comment documents the pause)

7. **Report completion**

   ---

   **Task Paused**

   Your progress on **{task-code}: {title}** has been saved.

   **What was saved:**
   - All your code changes are committed and backed up
   - Notes added to Lakar documenting where you left off

   **To continue later:**
   - Run `/zao:resume-task` to pick up where you left off
   - All your progress will be there waiting

   **You can now:**
   - Start a different task: `/zao:begin-task TSK-XXX`
   - Or close Claude Code - your work is safely saved

   ---

## Important

- **Lakar `create_comment` requires `user_id`.** Call `mcp__lakar__get_current_user` once at the start of the command and reuse the returned UUID for every `create_comment` call. _Lakar comments require `user_id`_ This applies to Lakar only — Note&Task resolves the author from the API key, so skip get_current_user / user_id when provider is notetask.
- Always commit and push before pausing so work isn't lost
- The pause notes should be detailed enough that anyone (including future you) can understand where things stand
- Don't switch branches automatically - let the user decide what to do next
