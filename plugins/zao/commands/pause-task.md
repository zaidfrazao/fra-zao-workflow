---
description: Save your progress and pause the current task to continue later
allowed-tools: Skill, mcp__lakar__get_task, mcp__lakar__update_task, mcp__lakar__create_comment, mcp__lakar__get_current_user, Bash, AskUserQuestion, mcp__notetask__get_task, mcp__notetask__update_task, mcp__notetask__create_comment, mcp__notetask__get_current_user, mcp__cairn__get_task_context, mcp__cairn__pause_task
---

Pause the current task and save progress for later.

### Project management provider

Resolve the PM provider with the `zao:pm-provider` skill (Skill tool) before the first PM call,
and use its mapping (`pm-mapping.md`) for every PM call below. Steps name the Lakar tool; for
`notetask` and `cairn` use the mapped equivalent. Where Cairn behaves differently, the step says
so under **Cairn:**. Lakar and Note&Task behaviour is unchanged.

This command is not used inside milestone runs (it has no `--autonomous` mode); a run is paused
with `/zao:run-milestone --pause`.

## Relevant MCP Tools
- **PM provider** (Lakar, Note&Task or Cairn): record where you left off. Lakar and Note&Task
  use a pause comment (and an optional status); Cairn stores a structured pause record.

## Prerequisites Check

1. **Find the task for the current branch**
   - Read `.claude/project.yaml` for `git.default_branch` and `git.branch_prefixes`
   - Run `git branch --show-current`
   - Find the task with the `zao:pm-provider` skill's branch rule (Lakar and Note&Task: strip a
     configured `git.branch_prefixes` value and read the task code; **Cairn:**
     `mcp__cairn__get_task_context { branch: "<current branch>" }`)
   - If the branch is `{git.default_branch}`, or the lookup finds no task:
     > "You're not on a task branch. There's nothing to pause."
     - Stop execution

2. **Get task context**
   - Use `mcp__lakar__get_task` to fetch task details (Cairn: the `get_task_context` result above)
   - **Cairn:** if `activeRun` shows this task `queued` or in flight in a milestone run, stop:
     > "{CODE} is part of run {activeRun.runId}; pause the run with `/zao:run-milestone --pause`."
   - **Cairn:** the task must be `in_progress` or `in_review` to pause. Otherwise say so and stop.

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
   - Review commits on this branch vs its base branch: `git log origin/{base}..HEAD --oneline`,
     where `{base}` is `{git.default_branch}` (**Cairn:** `git.baseBranch` from
     `get_task_context`, falling back to `{git.default_branch}`)
   - Identify files changed
   - Summarize what's implemented vs what's remaining (based on original task description;
     **Cairn:** also the plan's step statuses and the acceptance criteria)

5. **Record the pause**

   **Lakar and Note&Task:** use `mcp__lakar__create_comment` to document the pause:

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

   **Cairn:** store a structured pause record instead of the comment:
   `mcp__cairn__pause_task { code, progress: [<what's been completed>], remaining: [<what still needs to be done>], note: <user's optional notes>, branch: "{branch-name}" }`.
   Paused is a flag in Cairn: the status does not change, and `/zao:resume-task` reads this
   record back.

6. **Update the task status** (Lakar and Note&Task only, if there's a "Paused" or "On Hold" status)
   - Use `mcp__lakar__update_task` to update status if applicable
   - If no paused status exists, leave as "In Progress" (the comment documents the pause)
   - **Cairn:** skip this step; `pause_task` already set the paused flag.

7. **Report completion**

   ---

   **Task Paused**

   Your progress on **{task-code}: {title}** has been saved.

   **What was saved:**
   - All your code changes are committed and backed up
   - Notes added to {provider} documenting where you left off

   **To continue later:**
   - Run `/zao:resume-task` to pick up where you left off
   - All your progress will be there waiting

   **You can now:**
   - Start a different task: `/zao:begin-task TSK-XXX`
   - Or close Claude Code - your work is safely saved

   ---

## Important

- **Lakar `create_comment` requires `user_id`.** Call `mcp__lakar__get_current_user` once at the start of the command and reuse the returned UUID for every `create_comment` call. _Lakar comments require `user_id`_ This applies to Lakar only — Note&Task and Cairn resolve the author from the API key, so skip get_current_user / user_id when provider is notetask or cairn.
- Always commit and push before pausing so work isn't lost
- The pause notes should be detailed enough that anyone (including future you) can understand where things stand
- Don't switch branches automatically - let the user decide what to do next
- Never pause a task that a milestone run owns; pause the run instead
