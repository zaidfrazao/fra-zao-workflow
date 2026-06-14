---
description: Pick up a paused task and continue where you left off
allowed-tools: mcp__lakar__get_task, mcp__lakar__list_task_comments, mcp__lakar__update_task, Bash
---

Resume a previously paused task.

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
   - Use `mcp__lakar__update_task` to set status back to "In Progress"

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
