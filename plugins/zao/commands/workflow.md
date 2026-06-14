---
description: Learn about the development workflow and see where you currently are in the process
allowed-tools: mcp__lakar__get_task, mcp__lakar__list_tasks, Bash
---

Explain the /fra/zao development workflow to the user and show where they currently are if mid-task.

## Steps

1. **Detect current state**
   - Check if on a feature/bugfix/hotfix branch (not main/develop)
   - If on a task branch, extract the Lakar task code from the branch name (e.g., `feature/TSK-123-some-title` → `TSK-123`)
   - If a Lakar task is detected, fetch its current status using `mcp__lakar__get_task`
   - Check if a PR exists for the current branch using `gh pr view --json state,url 2>/dev/null`

2. **Present the workflow**

   Explain the workflow in simple, non-technical terms:

   ---

   **The /fra/zao Development Workflow**

   Here's how we work on tasks from start to finish:

   1. **Start a task** (`/zao:begin-task TSK-XXX`)
      - Fetches the task details from Lakar
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
      - Adds technical notes for Zaid if needed

   6. **Finish up** (`/zao:finish-task`)
      - After the PR is approved, this merges the work
      - Cleans everything up
      - Marks the task as complete

   **Other helpful commands:**
   - `/zao:check-status` - See where things stand and what to do next
   - `/zao:pause-task` - Save your progress to continue later
   - `/zao:resume-task` - Pick up where you left off
   - `/zao:cancel-task` - Abandon the current task if needed

   ---

3. **Show current position (if applicable)**

   If the user is mid-task, highlight where they are:

   - If on main/develop with no active task:
     > "You're not currently working on a task. To start, run `/zao:begin-task TSK-XXX` with your Lakar task code."

   - If on a task branch with Lakar status "In Progress" and no PR:
     > "You're currently working on **TSK-XXX: {title}**. You're in the build/refine phase. When ready, run `/zao:test-task` to check your work, or `/zao:submit-task` to submit for review."

   - If on a task branch with Lakar status "In Review" and PR exists:
     > "You're on **TSK-XXX: {title}** which is in review. PR: {url}. Once approved, run `/zao:finish-task` to merge and complete."

   - If Lakar status is paused/blocked:
     > "Task **TSK-XXX: {title}** is paused. Run `/zao:resume-task` to continue where you left off."

## Important

- Use friendly, non-technical language throughout
- Don't assume the user knows git, PRs, or branches - explain in terms of "tasks" and "work"
- Always end with a clear suggestion of what they can do next
