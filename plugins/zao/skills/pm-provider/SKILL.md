---
name: pm-provider
description: Resolves which project-management provider (lakar, notetask or cairn) the current repo uses from .claude/project.yaml, finds the task for the current git branch, and gives the exact MCP tool and arguments for every PM operation. Use it before any project-management call in a /fra or /zao command.
user-invocable: false
---

# PM provider

Every `/fra` and `/zao` command that talks to a project-management app resolves the provider
here, once, before its first PM call. This is the only place the resolution rule lives.

## 1. Resolve the provider (the one rule)

Read `.claude/project.yaml`:

1. If a `project_management:` block exists, use its `provider`. If the key is missing inside the
   block, use `lakar`.
2. Otherwise, if a legacy `lakar:` block exists, use `lakar` (statuses from `lakar.statuses.*`,
   client from `team.lakar_client`).
3. Otherwise, use `lakar` with the default status names (`Todo` / `In Progress` / `In Review` /
   `Done`).

The valid values are `lakar`, `notetask` and `cairn`. Any other value: stop and print
"Unknown project_management.provider '<value>'. Use lakar, notetask or cairn (run /fra:config)."

## 2. Status values

- **lakar, notetask:** status *values* always come from config (`project_management.statuses.*`,
  or legacy `lakar.statuses.*`). The mapping only says which tool and which field to use.
- **cairn:** the statuses are fixed: `backlog`, `todo`, `in_progress`, `in_review`, `done`,
  `canceled`. `project_management.statuses` is optional and ignored. If it is present, validate
  it: every value must normalise (trim, lowercase, spaces and hyphens become underscores,
  `cancelled` becomes `canceled`) to one of those, and `paused` and `blocked` must be `null`,
  because they are flags in Cairn. Otherwise print which key is wrong, say "omit `statuses:` for
  cairn", and stop.

## 3. Find the task for the current branch

- **cairn:** call `mcp__cairn__get_task_context { branch: "<git branch --show-current>" }`. Cairn
  matches the branch it stored for the task, then the task code in the branch name, so no parsing
  is needed. `not_found` means the branch is not a task branch.
- **lakar, notetask:** take every value in `git.branch_prefixes` (default `feature/`, `fix/`,
  `hotfix/`, `chore/`). If the branch starts with one of them (try the longest first), strip it;
  the task code is the leading `^([A-Z][A-Z0-9]*-[0-9]+)` of the rest, followed by `-`, `_` or
  the end of the name. No matching prefix or no code means the branch is not a task branch. This
  covers `fix/` and `chore/` branches as well as `feature/`.

"On a task branch" in a command means this lookup found a task. Comparing the branch against
`main` or `develop` by name is never enough.

## 4. The providers in brief

- **lakar:** task codes like `TSK-123`, passed as `id`. Status field `status`, values from config.
  Comments need `user_id` from `mcp__lakar__get_current_user`. Projects belong to a client.
- **notetask:** task codes like `NOTET-8`, passed as `code`. The status field is named `phase`,
  values from config. Projects are referred to by `projectIdentifier`; the workspace is only
  needed for labels.
- **cairn:** task codes like `QAA-14`, passed as `code`; milestones `QAA-M3`, phases `QAA-P2`.
  The MCP server is the user-scope server named `cairn` (tools `mcp__cairn__*`). Start every task
  step with `mcp__cairn__get_task_context`, which returns the task, acceptance criteria, saved
  plan, git links, latest test run, the active milestone run (`activeRun`) and
  `suggestedNextCommand`. The status field is `status` with the fixed values above. Comment
  authors come from the token. Writes that create something need a `clientKey`. Workspace and
  project come from `project_management.workspace` and `project_management.project_identifier`.
  `/zao:run-milestone` (milestone mode) works only with Cairn.

## 5. The mapping

Read `pm-mapping.md` in this skill's directory (the base directory shown when this skill
loaded). It has the exact tool and arguments of every operation for each provider, the Cairn
`clientKey` recipes and the gotchas. Use only the column for the resolved provider.

## 6. What to hand back to the command

State, in one or two lines, before continuing with the command:

- the provider;
- for lakar and notetask, the status values to use (`todo`, `in_progress`, `in_review`, `done`,
  and `canceled` if configured);
- for cairn, `workspace` and `projectIdentifier`.

If the provider's MCP tools are not available in this session (no `mcp__<provider>__*` tools),
say which server is missing and that `scripts/setup-mcp.sh` in the fra-zao-workflow repo
registers it, then stop.
