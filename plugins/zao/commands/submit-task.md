---
description: Submit your work for review - creates a pull request and updates the task status
allowed-tools: mcp__lakar__get_task, mcp__lakar__update_task, mcp__lakar__create_comment, mcp__lakar__get_current_user, mcp__pal__precommit, Bash, Read, mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user
---

Submit the current task for review.

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
- **Zen Precommit**: Validate changes before submission (security, bugs, quality)
- **Lakar**: Update task status to "In Review", add technical notes

## Prerequisites Check

1. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `team.lead` - name for technical notes (if set)
     - `git.default_branch` - for checking if on task branch
     - `lakar.statuses.in_review` - status name to set
     - `commits.footer` - commit message footer

2. **Check current branch**
   - Run `git branch --show-current`
   - If on `{git.default_branch}`:

     **For technical users:**
     > "On `{git.default_branch}`. No task branch to submit. Run `/zao:begin-task` first."

     **For non-technical users:**
     > "You're not on a task branch. There's nothing to submit. Run `/zao:begin-task TSK-XXX` to start a task first."

     - Stop execution

3. **Check for uncommitted changes**
   - Run `git status --porcelain`
   - If there are changes:

     **For technical users:**
     > "Uncommitted changes. Committing before submission."

     **For non-technical users:**
     > "You have unsaved changes. Let me save those first."

     ```bash
     git add -A
     git commit -m "chore: final changes before submission

     {commits.footer}"
     ```

4. **Get task context**
   - Parse Lakar task code from branch name
   - Use `mcp__lakar__get_task` to fetch task details

## Submission Process

1. **Announce submission start**

   **For technical users:**
   > "Preparing PR for **{task-code}: {title}**..."

   **For non-technical users:**
   > "Preparing to submit **{task-code}: {title}** for review..."

2. **Run precommit validation**
   - Use `mcp__pal__precommit` to validate all changes
   - Check for bugs, security issues, missing tests, code quality

   If critical/high severity issues found:

   **For technical users:**
   > "Precommit found {N} issues (critical: {X}, high: {Y}):"
   > {List issues}
   >
   > "Fix before submitting? Or proceed anyway?"

   **For non-technical users:**
   > "Found some issues that should be fixed before submitting:"
   > - {List issues in simple terms}
   >
   > "Would you like me to fix these first, or submit anyway?"

   - Wait for user decision
   - If they want fixes, suggest `/zao:fix-issue`

3. **Push the branch**
   ```bash
   git push -u origin $(git branch --show-current)
   ```

4. **Create the pull request**

   Generate PR body based on commits and task:

   ```bash
   gh pr create --title "{task-code}: {title}" --body "$(cat <<'EOF'
   ## Summary
   {Auto-generated summary of changes based on commits}

   ## Lakar Task
   {Link to Lakar task}

   ## Changes
   {Bullet list of what was changed}

   ## Testing
   - [ ] Automated tests pass
   - [ ] Manual testing completed
   - [ ] Visual review done

   ---
   {commits.footer}
   EOF
   )"
   ```

5. **Update Lakar status**
   - Use `mcp__lakar__update_task` to set status to `{lakar.statuses.in_review}`

6. **Add technical notes (if applicable and team.lead is set)**

   Review the implementation and determine if there are noteworthy technical details:
   - New libraries or dependencies added
   - Complex architectural decisions
   - Workarounds or trade-offs made
   - Performance considerations
   - Security-related changes
   - Breaking changes or migration notes

   If there are noteworthy items AND `team.lead` is configured, use `mcp__lakar__create_comment`:

   > **Technical Notes for @{team.lead}**
   >
   > {List of technical considerations}

   If `team.lead` is not set, skip the @mention:

   > **Technical Notes**
   >
   > {List of technical considerations}

   If nothing noteworthy, skip this step entirely (don't add an empty comment).

7. **Report completion**

   **For technical users:**

   ---

   **PR Created**

   - **PR:** {PR URL}
   - **Branch:** `{branch}` → `{git.default_branch}`
   - **Status:** {lakar.statuses.in_review}

   **Next:**
   - CI will run automatically
   - Address review feedback with `/zao:fix-issue`
   - After approval: `/zao:finish-task`

   ---

   **For non-technical users:**

   ---

   **Submitted for Review!**

   **Pull Request:** {PR URL}

   **What happens next:**
   1. Automated tests will run on GitHub (takes a few minutes)
   2. The code will be reviewed
   3. You may get feedback or requests for changes

   **While you wait:**
   - You can check the PR status at the link above
   - If changes are requested, use `/zao:fix-issue` to address them
   - Once approved, run `/zao:finish-task` to complete

   **To check status anytime:** `/zao:check-status`

   ---

## Error Handling

- **Push fails**:
  - Technical: "Push failed: {error}. Check remote permissions or conflicts."
  - Non-technical: "Couldn't push the code. {Explain reason - permissions, conflicts, etc.}"

- **PR creation fails**:
  - Technical: "PR creation failed: {error}. Check gh CLI auth."
  - Non-technical: "Couldn't create the pull request. {Explain reason}"

- **Lakar update fails**:
  - Technical: "PR created but Lakar update failed. Update status manually."
  - Non-technical: "Submitted the PR but couldn't update the task status. You may need to update it manually in Lakar."

## Important

- **Lakar `create_comment` requires `user_id`.** Call `mcp__lakar__get_current_user` once at the start of the command and reuse the returned UUID for every `create_comment` call. _Lakar comments require `user_id`_ This applies to Lakar only — Note&Task resolves the author from the API key, so skip get_current_user / user_id when provider is notetask.
- Always run precommit validation before submitting
- Use `team.lead` from config for technical notes - don't hardcode names
- If `team.lead` is empty, omit the @mention entirely
- Technical notes are only for significant considerations - don't add noise
- The PR description should be clear enough for reviewers to understand the changes
- Use `commits.footer` from config in commit messages
- Adjust all language based on `user.mode`
- End with clear expectations of what happens next
