---
description: Abandon the current task - cleans up branches and updates Lakar
allowed-tools: mcp__lakar__get_task, mcp__lakar__update_task, mcp__lakar__create_comment, mcp__lakar__get_current_user, Bash, AskUserQuestion
---

Cancel and abandon the current task.

## Relevant MCP Tools
- **Lakar**: Update task status, add cancellation notes

## Prerequisites Check

1. **Check current branch**
   - Run `git branch --show-current`
   - Store as `{current-branch}`
   - If on `main` or `develop`:
     > "You're not on a task branch. There's nothing to cancel."
     - Stop execution

2. **Get task context**
   - Parse Lakar task code from branch name
   - Use `mcp__lakar__get_task` to fetch task details

## Cancellation Process

1. **Confirm cancellation**
   - Use `AskUserQuestion`:
     > "Are you sure you want to cancel **{task-code}: {title}**?
     >
     > This will:
     > - Delete the working branch (local and remote)
     > - Move the task back to the backlog in Lakar
     >
     > Any code changes will be lost. Proceed?"

   - If they don't confirm, stop execution

2. **Ask for cancellation reason**
   - Use `AskUserQuestion`:
     > "Why is this task being cancelled? (This helps track decisions)
     >
     > 1. Requirements changed
     > 2. Task is no longer needed
     > 3. Blocked by something else
     > 4. Other (please explain)"

3. **Check for a PR**
   ```bash
   gh pr view --json url,state 2>/dev/null || echo "NO_PR"
   ```

   If a PR exists:
   - Close it:
     ```bash
     gh pr close --delete-branch
     ```

4. **Switch to main**
   ```bash
   git checkout main
   git pull origin main
   ```

5. **Delete the local branch**
   ```bash
   git branch -D {current-branch}
   ```

6. **Delete the remote branch** (if it exists and wasn't deleted with PR)
   ```bash
   git push origin --delete {current-branch} 2>/dev/null || true
   ```

7. **Add cancellation notes to Lakar**

   Use `mcp__lakar__create_comment`:

   > **Task Cancelled**
   >
   > **Reason:** {user's selected/provided reason}
   >
   > **Work completed before cancellation:**
   > - {Brief summary of any work that was done, if any}
   >
   > **Branch:** `{branch-name}` (deleted)

8. **Update Lakar status**
   - Use `mcp__lakar__update_task` to set status to "Backlog" or "Todo"
   - This puts it back in the queue if someone wants to pick it up later

9. **Report completion**

   ---

   **Task Cancelled**

   **{task-code}: {title}** has been cancelled.

   **What happened:**
   - Working branch deleted
   - Task moved back to backlog in Lakar
   - Cancellation reason documented

   **The task can be restarted later if needed** by running `/zao:begin-task {task-code}`

   **You're now on the main branch.**

   To start a different task: `/zao:begin-task TSK-XXX`

   ---

## Error Handling

- **Branch deletion fails**: "Couldn't delete the branch, but I've updated Lakar. You can delete the branch manually later."

- **PR close fails**: "Couldn't close the PR automatically. You may need to close it manually at {url}"

- **Lakar update fails**: "Branch cleaned up, but couldn't update Lakar. You may need to move the task to backlog manually."

## Important

- **Lakar `create_comment` requires `user_id`.** Call `mcp__lakar__get_current_user` once at the start of the command and reuse the returned UUID for every `create_comment` call. _Lakar comments require `user_id`_
- Always confirm before cancelling - this is destructive
- Document the cancellation reason so there's a record of why
- Put the task back in backlog (not delete it) so it can be reconsidered
- Any completed work is lost - if they might want it later, suggest `/zao:pause-task` instead
