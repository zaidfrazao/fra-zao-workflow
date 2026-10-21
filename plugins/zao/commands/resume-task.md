---
description: Pick up a paused task and continue where you left off
allowed-tools: Skill, mcp__lakar__get_task, mcp__lakar__list_task_comments, mcp__lakar__update_task, Bash, mcp__notetask__get_task, mcp__notetask__list_task_comments, mcp__notetask__update_task, mcp__cairn__get_task_context, mcp__cairn__resume_task, mcp__cairn__update_task, mcp__cairn__list_tasks
---

Resume a previously paused task.

### Project management provider

Resolve the PM provider with the `zao:pm-provider` skill (Skill tool) before the first PM call,
and use its mapping (`pm-mapping.md`) for every PM call below. Steps name the Lakar tool; for
`notetask` and `cairn` use the mapped equivalent. Where Cairn behaves differently, the step says
so under **Cairn:**. Lakar and Note&Task behaviour is unchanged.

This command is not used inside milestone runs (it has no `--autonomous` mode); a run is resumed
with `/zao:run-milestone --resume`.

## Relevant MCP Tools
- **PM provider** (Lakar, Note&Task or Cairn): fetch task details and the pause notes (Cairn:
  the structured pause record returned by `resume_task`)

## Process

1. **Determine which task to resume**

   a. **Check current branch**
      - Read `.claude/project.yaml` for `git.default_branch` and `git.branch_prefixes`
      - Run `git branch --show-current`

   b. **If already on a task branch** (the `zao:pm-provider` skill's branch rule finds a task):
      - Lakar and Note&Task: the task code comes from the branch name
      - **Cairn:** `mcp__cairn__get_task_context { branch: "<current branch>" }`
      - Use this task

   c. **If on `{git.default_branch}`** (or the branch is not a task branch):
      - **Lakar and Note&Task:** list recent task branches, using every configured
        `git.branch_prefixes` value (default `feature/`, `fix/`, `hotfix/`, `chore/`):
        ```bash
        git branch --list "{prefix-1}*" --list "{prefix-2}*" ... --sort=-committerdate | head -5
        ```
      - **Cairn:** list paused tasks instead of guessing from branches:
        `mcp__cairn__list_tasks { projectIdentifier: <PROJ>, paused: true }`
      - If tasks found, present options:
        > "Found these paused tasks:
        > 1. {branch-1 or code-1} - {task title if determinable}
        > 2. {branch-2 or code-2}
        > ...
        >
        > Which would you like to resume? (Enter the number or task code)"
      - Wait for user selection
      - If none found:
        > "No paused tasks found. Run `/zao:begin-task TSK-XXX` to start a new task."
        - Stop execution

   d. **Cairn:** for the chosen task, call `mcp__cairn__get_task_context { code }` if you have not
      already. If `activeRun` shows the task `queued` or in flight in a milestone run, stop:
      > "{CODE} is part of run {activeRun.runId}; resume the run with `/zao:run-milestone --resume`."

2. **Fetch the pause notes**
   - **Lakar and Note&Task:** use `mcp__lakar__get_task` to get task info and
     `mcp__lakar__list_task_comments` to find pause notes (comments containing "Task Paused" or
     similar markers)
   - **Cairn:** `mcp__cairn__resume_task { code }`. It clears the paused flag and returns the pause
     record (`progress`, `remaining`, `note`, `branch`, who paused it and when). No
     `list_task_comments` call is needed. `pause: null` means the task was not paused; carry on
     with the task's linked branch.

3. **Switch to the task branch** (if not already on it)
   - The branch is the one chosen above (**Cairn:** the pause record's `branch`, else
     `git.branch` from `get_task_context`)
   ```bash
   git checkout {branch-name}
   git pull origin {branch-name}
   ```

4. **Display where you left off**

   ---

   **Resuming: {task-code}: {title}**

   **Where you left off:**
   {Progress and remaining work from the pause notes (Cairn: the pause record's `progress`,
   `remaining` and `note`)}

   **Branch:** `{branch-name}`

   ---

5. **Update the task status** (Lakar and Note&Task, if it was changed to Paused/On Hold)
   - Use `mcp__lakar__update_task` to set status back to `{statuses.in_progress}` (Note&Task:
     `update_task { code, phase }` per the mapping)
   - **Cairn:** `resume_task` already cleared the paused flag. Only if the status is no longer
     `in_progress` or `in_review` (for example someone moved it back to `todo`), set it with
     `mcp__cairn__update_task { code, status: "in_progress" }`.

6. **Show current state**

   - Check for any uncommitted changes: `git status --porcelain`
   - Show recent commits on this branch against its base branch, where `{base}` is
     `{git.default_branch}` (**Cairn:** `git.baseBranch` from `get_task_context`, falling back to
     `{git.default_branch}`):
     ```bash
     git log origin/{base}..HEAD --oneline
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

   **Cairn:** lead with `suggestedNextCommand` from `get_task_context` when it is present.

   ---

## Error Handling

- **Branch doesn't exist locally but exists on remote**:
  ```bash
  git fetch origin
  git checkout -b {branch-name} origin/{branch-name}
  ```

- **Branch has conflicts with its base branch**:
  > "The `{base}` branch has changed since you paused. Would you like me to update your branch with the latest changes? (This might require resolving some conflicts)"

- **Can't find pause notes**:
  > "I couldn't find pause notes for this task, but here's what I can see from the code changes..."
  - Fall back to analyzing git history

## Important

- Always pull latest changes when resuming in case work was done from another machine
- Make it easy for the user to understand exactly where they left off
- Provide clear guidance on what to do next
- Never resume a task that a milestone run owns; resume the run instead
