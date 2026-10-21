---
description: Abandon the current task - cleans up branches and updates the task in your PM app
allowed-tools: Skill, mcp__lakar__get_task, mcp__lakar__update_task, mcp__lakar__create_comment, mcp__lakar__get_current_user, Bash, AskUserQuestion, mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user, mcp__cairn__get_task_context, mcp__cairn__update_task, mcp__cairn__create_comment, mcp__cairn__update_task_git
---

Cancel and abandon the current task.

### Project management provider

Resolve the PM provider with the `zao:pm-provider` skill (Skill tool) before the first PM call,
and use its mapping (`pm-mapping.md`) for every PM call below. Steps name the Lakar tool; for
`notetask` and `cairn` use the mapped equivalent. Where Cairn behaves differently, the step says
so under **Cairn:**. Lakar and Note&Task behaviour is unchanged.

This command is not used inside milestone runs (it has no `--autonomous` mode). Cancelling means
"abandon this attempt", not "delete the work": the task stays in the PM app so it can be picked up
again.

## Relevant MCP Tools
- **PM provider** (Lakar, Note&Task or Cairn): update the task status, add cancellation notes;
  Cairn also records the closed PR

## Prerequisites Check

1. **Find the task for the current branch**
   - Read `.claude/project.yaml` for `git.default_branch` and `git.branch_prefixes`
   - Run `git branch --show-current`
   - Store as `{current-branch}`
   - Find the task with the `zao:pm-provider` skill's branch rule (Lakar and Note&Task: strip a
     configured `git.branch_prefixes` value and read the task code; **Cairn:**
     `mcp__cairn__get_task_context { branch: "{current-branch}" }`)
   - If the branch is `{git.default_branch}`, or the lookup finds no task:
     > "You're not on a task branch. There's nothing to cancel."
     - Stop execution

2. **Get task context**
   - Use `mcp__lakar__get_task` to fetch task details (Cairn: the `get_task_context` result above)
   - **Cairn:** if `activeRun` shows this task `queued` or in flight in a milestone run, stop:
     > "{CODE} is part of run {activeRun.runId}. Skip it from the run in Cairn, or cancel the run with `/zao:run-milestone --cancel \"<reason>\"`."
   - **Cairn:** note the task branch's HEAD now, before any branch is deleted:
     `git rev-parse --short=7 HEAD` → `{sha7}` (used in the comment's `clientKey`).

## Cancellation Process

1. **Confirm cancellation**
   - Use `AskUserQuestion`:
     > "Are you sure you want to cancel **{task-code}: {title}**?
     >
     > This will:
     > - Delete the working branch (local and remote)
     > - Move the task back to the backlog in {provider}
     >
     > Any code changes will be lost. Proceed?"

     **Cairn:** replace the second bullet with "Update the task in Cairn according to the reason
     you give next: canceled if it's no longer needed, back to todo and flagged blocked if it's
     blocked by something else, otherwise back to the backlog."

   - If they don't confirm, stop execution

2. **Ask for cancellation reason**
   - Use `AskUserQuestion`:
     > "Why is this task being cancelled? (This helps track decisions)
     >
     > 1. Requirements changed
     > 2. Task is no longer needed
     > 3. Blocked by something else
     > 4. Other (please explain)"
   - **Cairn:** for *Blocked by something else*, also ask what blocks it (a short reason, and any
     task codes it waits on).

3. **Check for a PR**
   ```bash
   gh pr view --json number,url,state 2>/dev/null || echo "NO_PR"
   ```

   If a PR exists:
   - Note its `number` (Cairn records it in step 8)
   - Close it:
     ```bash
     gh pr close --delete-branch
     ```

4. **Switch to the default branch**
   ```bash
   git checkout {git.default_branch}
   git pull origin {git.default_branch}
   ```

5. **Delete the local branch**
   ```bash
   git branch -D {current-branch}
   ```

6. **Delete the remote branch** (if it exists and wasn't deleted with PR)
   ```bash
   git push origin --delete {current-branch} 2>/dev/null || true
   ```

7. **Add cancellation notes**

   Use `mcp__lakar__create_comment`:

   > **Task Cancelled**
   >
   > **Reason:** {user's selected/provided reason}
   >
   > **Work completed before cancellation:**
   > - {Brief summary of any work that was done, if any}
   >
   > **Branch:** `{branch-name}` (deleted)

   **Cairn:** `mcp__cairn__create_comment { code, kind: "cancellation", content: <the notes above>, clientKey: "<CODE>:cancellation:{sha7}" }`.

8. **Update the task status**
   - **Lakar:** use `mcp__lakar__update_task` to set status to "Backlog" or "Todo"
     - This puts it back in the queue if someone wants to pick it up later
   - **Note&Task:** prefer the `canceled` phase (`project_management.statuses.canceled`) if set,
     else `todo`.
   - **Cairn:** map the reason, so work that is still wanted is never canceled:

     | Reason | Call |
     |---|---|
     | Task is no longer needed | `mcp__cairn__update_task { code, status: "canceled" }` |
     | Requirements changed | `mcp__cairn__update_task { code, status: "backlog" }` |
     | Blocked by something else | `mcp__cairn__update_task { code, status: "todo", blocked: { reason, blockedBy: [<task codes named>] } }` (omit `blockedBy` when none were named) |
     | Other | `mcp__cairn__update_task { code, status: "backlog" }` |

     If a PR existed, record that it is closed:
     `mcp__cairn__update_task_git { code, pr: { number: {pr-number}, state: "closed" } }`.

9. **Report completion**

   ---

   **Task Cancelled**

   **{task-code}: {title}** has been cancelled.

   **What happened:**
   - Working branch deleted
   - Task moved back to backlog in {provider} (Cairn: canceled, back to the backlog, or back to
     todo and flagged blocked, per the reason)
   - Cancellation reason documented

   **The task can be restarted later if needed** by running `/zao:begin-task {task-code}`
   (**Cairn:** `/zao:begin-task {task-code} --reopen` when the task was set to `canceled`, because
   a canceled task needs `--reopen`; `/zao:begin-task {task-code}` otherwise)

   **You're now on the `{git.default_branch}` branch.**

   To start a different task: `/zao:begin-task TSK-XXX`

   ---

## Error Handling

- **Branch deletion fails**: "Couldn't delete the branch, but I've updated the task in {provider}. You can delete the branch manually later."

- **PR close fails**: "Couldn't close the PR automatically. You may need to close it manually at {url}"

- **PM update fails**: "Branch cleaned up, but couldn't update the task in {provider}. You may need to move the task to backlog manually."

## Important

- **Lakar `create_comment` requires `user_id`.** Call `mcp__lakar__get_current_user` once at the start of the command and reuse the returned UUID for every `create_comment` call. _Lakar comments require `user_id`_ This applies to Lakar only — Note&Task and Cairn resolve the author from the API key, so skip get_current_user / user_id when provider is notetask or cairn.
- Always confirm before cancelling - this is destructive
- Document the cancellation reason so there's a record of why
- Put the task back in backlog (not delete it) so it can be reconsidered; with Cairn, only "no longer needed" sets `canceled`
- Any completed work is lost - if they might want it later, suggest `/zao:pause-task` instead
- Never cancel a task that a milestone run owns; skip it from the run or cancel the run instead
