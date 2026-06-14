---
description: Start working on a Lakar task - fetches details, creates a plan, and prepares everything
allowed-tools: mcp__lakar__get_task, mcp__lakar__update_task, mcp__pal__planner, mcp__tavily__tavily_search, Bash, Read, mcp__notetask__get_task, mcp__notetask__update_task
---

Start working on the Lakar task: $ARGUMENTS

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
- **Lakar**: Fetch task details, update status to "In Progress"
- **Zen Planner**: Create a comprehensive implementation plan
- **Tavily**: Research best practices, patterns, or approaches when planning

## Prerequisites Check

1. **Validate argument**
   - If no argument provided, respond: "Please provide a task code. Example: `/zao:begin-task TSK-123`"
   - The argument should be a Lakar task code (e.g., `TSK-123`)

2. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `project.name` and `project.description` - for planning context
     - `project.type` - for planning context
     - `git.default_branch` - branch to start from
     - `git.branch_prefixes` - for branch naming
     - `lakar.statuses.in_progress` - status name to set

3. **Check current branch**
   - Run `git branch --show-current`
   - If NOT on `{git.default_branch}`:

     **For technical users:**
     > "Currently on `{branch}`. Switch to `{git.default_branch}` first, or use `/zao:finish-task` or `/zao:cancel-task` to complete the current task."

     **For non-technical users:**
     > "You're still working on another task. Finish that one first with `/zao:finish-task`, or cancel it with `/zao:cancel-task`, then try again."

     - Stop execution

4. **Check for uncommitted changes**
   - Run `git status --porcelain`
   - If there are changes:

     **For technical users:**
     > "Uncommitted changes detected. Stash, commit, or discard before starting a new task."

     **For non-technical users:**
     > "You have unsaved changes that might get lost. Would you like me to save these first, or discard them?"

     - Wait for user input before proceeding

5. **Ensure default branch is up to date**
   ```bash
   git fetch origin
   git pull origin {git.default_branch}
   ```

## Steps

1. **Fetch the Lakar task**
   - Use `mcp__lakar__get_task` with the provided issue code
   - If not found:

     **For technical users:**
     > "Issue `{code}` not found in Lakar. Verify the issue code."

     **For non-technical users:**
     > "Couldn't find task {code}. Please check the code is correct (you can find it in Lakar, like TSK-123)."

   - Extract: title, description, labels, acceptance criteria (if any), current status

2. **Present the task summary**

   **For technical users:**

   ---

   **{code}: {title}**

   {description}

   **Acceptance Criteria:**
   {List from task or note if none specified}

   **Labels:** {labels}

   ---

   **For non-technical users:**

   ---

   **Task: {code}**

   **{title}**

   {description - simplified if very technical}

   **What needs to be done:**
   {List acceptance criteria or key requirements in simple bullet points}

   ---

3. **Update Lakar status**
   - Use `mcp__lakar__update_task` to set status to `{lakar.statuses.in_progress}`

   **For technical users:**
   > "Status → In Progress"

   **For non-technical users:**
   > "Task marked as in progress."

4. **Create the working branch**
   - Determine branch type from labels/title:
     - Bug label or "fix"/"bug" in title → use `{git.branch_prefixes.bugfix}`
     - Chore label or "chore" in title → use `{git.branch_prefixes.chore}`
     - Otherwise → use `{git.branch_prefixes.feature}`
   - Create branch: `{prefix}{issue-code}-{kebab-case-short-title}`
     - Example: `feature/TSK-123-add-user-auth`
     - Keep title portion under 50 chars
   - Run:
     ```bash
     git checkout -b {branch-name}
     git push -u origin {branch-name}
     ```

   **For technical users:**
   > "Branch: `{branch-name}` (pushed to origin)"

   **For non-technical users:**
   > "Created a workspace for this task and saved it to GitHub."

5. **Research and plan (using Zen Planner)**

   Use `mcp__pal__planner` to create an implementation plan.

   Before planning, optionally use `mcp__tavily__tavily_search` if the task involves:
   - Unfamiliar technologies or patterns
   - Third-party integrations
   - Complex architectural decisions

   Planning context should include:
   - The full task description and requirements
   - Project context from config: "{project.name} - {project.description}" (type: {project.type})
   - Any relevant technical constraints from the PRD (if available in docs/PRD.md)

   Use at least 3 planning steps to develop a thorough plan.

6. **Present the plan for approval**

   **For technical users:**

   ---

   **Implementation Plan**

   {Present plan with technical details}

   **Estimated complexity:** {Low/Medium/High}

   **Questions:**
   - Any requirements unclear?
   - Approach acceptable?

   Ready to implement? Run `/zao:implement-task`

   ---

   **For non-technical users:**

   ---

   **Here's the plan for building this:**

   {Present plan in simple, numbered steps - focus on what, not how}

   **Before we start building:**
   - Does this plan make sense to you?
   - Is there anything you'd like to change or clarify?
   - Any requirements I might have missed?

   When you're happy with the plan, run `/zao:implement-task` to start building.

   ---

## Error Handling

- **Lakar connection failed**:
  - Technical: "Lakar API error: {error}. Check network and auth."
  - Non-technical: "Couldn't connect to Lakar. Please check your connection and try again."

- **Git errors**: Explain in appropriate terms what went wrong and offer to help fix it

- **Branch already exists**:
  - Technical: "Branch `{branch}` exists. Checkout existing or delete and recreate?"
  - Non-technical: "A workspace for this task already exists. Would you like to continue from where it left off, or start fresh?"

## Important

- Adjust all language based on `user.mode` from config
- Use branch prefixes from config, not hardcoded values
- Use project context from config for planning, not hardcoded project descriptions
- The plan should match user.mode - technical details for technical users, outcomes for non-technical
- End with a clear call to action (approve the plan)
- Don't start implementing - this command only plans
