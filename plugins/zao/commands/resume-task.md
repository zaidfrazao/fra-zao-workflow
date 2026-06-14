---
description: Pick up a paused task and continue where you left off
allowed-tools: mcp__lakar__get_task, mcp__lakar__list_task_comments, mcp__lakar__update_task, Bash, mcp__notetask__get_task, mcp__notetask__list_task_comments, mcp__notetask__update_task
---

Resume a previously paused task.

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
- **Lakar**: Fetch task details and pause notes

## Process

1. **Determine which task to resume**

   a. **Check current branch**
      - Run `git branch --show-current`

   b. **If already on a task branch:**
      - Parse Lakar task code from branch name
      - Use this task

   c. **If on main/develop:**
      - List recent task branches:
        ```bash
        git branch --list "feature/*" --list "bugfix/*" --list "hotfix/*" --sort=-committerdate | head -5
        ```
      - If branches found, present options:
        > "Found these paused tasks:
        > 1. {branch-1} - {task title if determinable}
        > 2. {branch-2}
        > ...
        >
        > Which would you like to resume? (Enter the number or task code)"
      - Wait for user selection
      - If no branches found:
        > "No paused tasks found. Run `/zao:begin-task TSK-XXX` to start a new task."
        - Stop execution

2. **Switch to the task branch** (if not already on it)
   ```bash
   git checkout {branch-name}
   git pull origin {branch-name}
   ```

3. **Fetch task details from Lakar**
   - Use `mcp__lakar__get_task` to get task info
   - Use `mcp__lakar__list_task_comments` to find pause notes

4. **Find and display pause notes**

   Look for comments containing "Task Paused" or similar markers:

   ---

   **Resuming: {task-code}: {title}**

   **Where you left off:**
   {Extract progress and remaining work from pause notes}

   **Branch:** `{branch-name}`

   ---

5. **Update Lakar status** (if it was changed to Paused/On Hold)
   - Use `mcp__lakar__update_task` to set status back to `{statuses.in_progress}` (or the notetask equivalent `update_task { code, phase }` per the provider block above)

6. **Show current state**

   - Check for any uncommitted changes: `git status --porcelain`
   - Show recent commits on this branch:
     ```bash
     git log main..HEAD --oneline
     ```

7. **Provide next steps**

   ---

   **Ready to continue!**

   **What's been done:**
   - {Summary from commits/pause notes}

   **What's next:**
   - {Remaining work from pause notes}

   **Commands you can use:**
   - `/zao:implement-task` - Continue building (if implementation was in progress)
   - `/zao:fix-issue <description>` - Fix any issues
   - `/zao:adjust-feature <description>` - Make adjustments
   - `/zao:test-task` - Test when ready
   - `/zao:submit-task` - Submit for review when complete

   ---

## Error Handling

- **Branch doesn't exist locally but exists on remote**:
  ```bash
  git fetch origin
  git checkout -b {branch-name} origin/{branch-name}
  ```

- **Branch has conflicts with main**:
  > "The main branch has changed since you paused. Would you like me to update your branch with the latest changes? (This might require resolving some conflicts)"

- **Can't find pause notes**:
  > "I couldn't find pause notes for this task, but here's what I can see from the code changes..."
  - Fall back to analyzing git history

## Important

- Always pull latest changes when resuming in case work was done from another machine
- Make it easy for the user to understand exactly where they left off
- Provide clear guidance on what to do next
