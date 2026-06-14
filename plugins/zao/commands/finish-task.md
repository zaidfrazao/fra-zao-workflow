---
description: Complete the task - merge the PR, clean up, and mark as done
allowed-tools: mcp__lakar__get_task, mcp__lakar__update_task, mcp__lakar__create_comment, mcp__lakar__get_current_user, Bash, AskUserQuestion, Read, KillShell, mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user
---

Finish the current task by merging and cleaning up.

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
- **Lakar**: Mark task as "Done", add closing notes if needed
- **GitHub CLI**: Merge PR, delete branches
- **KillShell**: Kill any background processes started during the task

## Prerequisites Check

1. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `team.lead` - name for closing notes (if set)
     - `git.default_branch` - branch to merge to
     - `git.merge_strategy` - squash, merge, or rebase
     - `git.delete_branch_after_merge` - whether to delete branch
     - `git.require_pr_approval` - whether PR must be approved before merging (default: true)
     - `lakar.statuses.done` - status name to set

2. **Check current branch**
   - Run `git branch --show-current`
   - Store as `{current-branch}`
   - If on `{git.default_branch}`:

     **For technical users:**
     > "On `{git.default_branch}`. No task branch to finish. Run `/zao:check-status` to see current state."

     **For non-technical users:**
     > "You're not on a task branch. There's nothing to finish. Run `/zao:check-status` to see where you are."

     - Stop execution

3. **Get task context**
   - Parse Lakar task code from branch name
   - Use `mcp__lakar__get_task` to fetch task details

4. **Check PR status**
   ```bash
   gh pr view --json state,reviewDecision,statusCheckRollup,url
   ```

   - If no PR exists:

     **For technical users:**
     > "No PR found for this branch. Run `/zao:submit-task` first."

     **For non-technical users:**
     > "There's no pull request for this task yet. Run `/zao:submit-task` first to create one."

     - Stop execution

   - If `git.require_pr_approval` is true (default) AND PR is not approved:

     **For technical users:**
     > "PR not approved. Status: {reviewDecision}. URL: {url}"

     **For non-technical users:**
     > "The pull request hasn't been approved yet."
     >
     > "**Status:** {review status in plain terms}"
     > "**PR:** {url}"
     >
     > "Once it's approved, run `/zao:finish-task` again."

     - Stop execution

   - If `git.require_pr_approval` is false, skip the approval check and proceed

   - If CI checks are failing:

     **For technical users:**
     > "CI failing: {list failed checks}. Proceed anyway?"

     **For non-technical users:**
     > "Some automated checks are failing on the pull request."
     >
     > "**Failed checks:** {list in simple terms}"
     >
     > "Would you like to proceed anyway, or fix the issues first?"

     - Use `AskUserQuestion` to get their decision
     - If they want to fix, suggest `/zao:fix-issue`

## Finish Process

1. **Announce completion start**

   **For technical users:**
   > "Merging **{task-code}: {title}**..."

   **For non-technical users:**
   > "Finishing up **{task-code}: {title}**..."

2. **Merge the pull request**

   Use the merge strategy from config:

   - If `git.merge_strategy` is "squash":
     ```bash
     gh pr merge --squash {--delete-branch if git.delete_branch_after_merge}
     ```

   - If `git.merge_strategy` is "merge":
     ```bash
     gh pr merge --merge {--delete-branch if git.delete_branch_after_merge}
     ```

   - If `git.merge_strategy` is "rebase":
     ```bash
     gh pr merge --rebase {--delete-branch if git.delete_branch_after_merge}
     ```

3. **Switch back to default branch**
   ```bash
   git checkout {git.default_branch}
   git pull origin {git.default_branch}
   ```

4. **Delete branches** (if `git.delete_branch_after_merge`)

   Local:
   ```bash
   git branch -D {current-branch}
   ```

   Remote (idempotent — step 2's `--delete-branch` only fires when *this* command does the merge; if the PR was merged externally via the web UI or another tool, the remote is still alive):
   ```bash
   if git ls-remote --exit-code --heads origin {current-branch} >/dev/null 2>&1; then
     git push origin --delete {current-branch}
   fi
   ```

   Don't fail the command if either deletion errors — surface a warning per the Error Handling section.

5. **Kill background processes**

   Kill any background shell processes that were started during this task (e.g., dev servers, watch processes):

   - Use the `KillShell` tool to terminate any running background shells
   - This ensures dev servers started by `/zao:test-task` or during development are stopped
   - Don't fail if there are no background processes to kill

6. **Clean up Claude Code artifacts**

   Remove temporary files created during development:

   ```bash
   # Remove Playwright MCP screenshots
   rm -rf .playwright-mcp/

   # Remove changeset files from precommit checks
   rm -rf .changeset/
   ```

   This cleanup is silent - don't report if these directories don't exist.

7. **Update Lakar status**
   - Use `mcp__lakar__update_task` to set status to `{lakar.statuses.done}`

8. **Add closing notes (if applicable)**

   Review the entire task implementation and determine if there are closing technical notes:
   - Architectural decisions that affect future work
   - Technical debt introduced that should be addressed later
   - Dependencies or libraries that need monitoring for updates
   - Performance implications to watch
   - Areas that might need refactoring in the future
   - Documentation that should be created

   If there are noteworthy closing items:

   If `team.lead` is configured, use `mcp__lakar__create_comment`:

   > **Closing Notes for @{team.lead}**
   >
   > {List of technical considerations for future reference}

   If `team.lead` is not set:

   > **Closing Notes**
   >
   > {List of technical considerations for future reference}

   If nothing noteworthy, skip this step.

9. **Report completion**

   **For technical users:**

   ---

   **Task Complete**

   - **{task-code}:** {title}
   - **Merged:** `{current-branch}` → `{git.default_branch}` ({git.merge_strategy})
   - **Status:** {lakar.statuses.done}
   - **Branch:** {deleted/kept}

   Ready for next task: `/zao:begin-task TSK-XXX`

   ---

   **For non-technical users:**

   ---

   **Task Complete!**

   **{task-code}: {title}** is now done.

   **Summary:**
   - Pull request merged
   - Code is now in the main branch
   - Task marked as complete in Lakar
   - Working branch cleaned up

   **You're back on the main branch and ready for your next task.**

   To start a new task: `/zao:begin-task TSK-XXX`

   ---

## Error Handling

- **Merge conflicts**:
  - Technical: "Merge conflict. Resolve manually or rebase. Files: {list}"
  - Non-technical: "There are conflicts that need to be resolved before merging. This can happen when other changes were made to main. Would you like me to help resolve these conflicts?"
  - If yes, help resolve conflicts, then re-run `/zao:finish-task`

- **PR merge fails**:
  - Technical: "Merge failed: {error}"
  - Non-technical: "Couldn't merge the pull request. {Explain reason}"

- **Local branch deletion fails**:
  - Technical: "Merge succeeded. Local branch deletion failed - delete manually: `git branch -D {branch}`"
  - Non-technical: "The task is complete, but I couldn't clean up the local branch. You can ignore this or ask for help cleaning it up later."

- **Remote branch deletion fails**:
  - Technical: "Merge succeeded. Remote branch deletion failed - delete manually: `git push origin --delete {branch}`. Common cause: PR merged via web UI on a repo without 'Automatically delete head branches' enabled (GitHub → Settings → General → Pull Requests)."
  - Non-technical: "The task is complete, but the branch on GitHub is still there. It's safe — just visual clutter. Enable 'Automatically delete head branches' in the repo settings to fix this for future PRs."

- **Lakar update fails**:
  - Technical: "Merged successfully. Lakar update failed - mark as Done manually."
  - Non-technical: "The PR was merged successfully! But I couldn't update Lakar. You may need to mark it as Done manually."

## Important

- **Lakar `create_comment` requires `user_id`.** Call `mcp__lakar__get_current_user` once at the start of the command and reuse the returned UUID for every `create_comment` call. _Lakar comments require `user_id`_ This applies to Lakar only — Note&Task resolves the author from the API key, so skip get_current_user / user_id when provider is notetask.
- Check `git.require_pr_approval` from config - if true (default), require PR approval before merging
- Use `git.merge_strategy` from config - don't assume squash
- Use `git.delete_branch_after_merge` from config
- Use `team.lead` from config for closing notes - don't hardcode names
- If `team.lead` is empty, omit the @mention
- Closing notes are only for significant future considerations - don't add noise
- Adjust all language based on `user.mode`
- End with a clear "what's next" message
