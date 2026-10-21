---
description: Run automated tests and checks on your work before submitting
argument-hint: "[--profile quick|standard|full] [--autonomous] [--gate <gateRef>]"
allowed-tools: Skill, mcp__cairn__get_task_context, mcp__cairn__record_test_run, mcp__cairn__mark_acceptance_criteria, mcp__cairn__create_attachment_upload, mcp__cairn__complete_attachment_upload, mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_snapshot, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_click, mcp__plugin_playwright_playwright__browser_type, mcp__plugin_playwright_playwright__browser_fill_form, mcp__plugin_playwright_playwright__browser_press_key, mcp__plugin_playwright_playwright__browser_select_option, mcp__plugin_playwright_playwright__browser_wait_for, mcp__plugin_playwright_playwright__browser_hover, mcp__plugin_playwright_playwright__browser_evaluate, mcp__plugin_playwright_playwright__browser_console_messages, mcp__plugin_playwright_playwright__browser_close, Bash, Read, TaskStop
---

Run automated tests and checks on the current task. $ARGUMENTS

### Project management provider

Resolve the PM provider with the `zao:pm-provider` skill (Skill tool) before the first PM call,
and use its mapping (`pm-mapping.md`) for every PM call below. Steps name the Lakar tool; for
`notetask` and `cairn` use the mapped equivalent. Where Cairn behaves differently, the step says
so under **Cairn:**. Lakar and Note&Task behaviour is unchanged: they keep test results in the
chat, so this command makes PM calls only for Cairn.

### Arguments

- `--profile quick|standard|full`: which checks to run (see step 2). Default `standard`; with
  `--autonomous` the default is `quick`.
- `--autonomous` and `--gate <gateRef>`: milestone-run mode, see **Autonomous mode** below.

## Autonomous mode (`--autonomous`)

Only the `zao:task-runner` agent passes `--autonomous`, for the task a Cairn milestone run is
working on. In this mode the command:

1. **Never asks.** It never calls `AskUserQuestion` and never waits for input; every interactive
   point below has an autonomous rule.
2. **Takes run context from Cairn**: `activeRun` from `mcp__cairn__get_task_context` (base
   branch, check names, policy flags, `approvedGate`), never from the conversation.
3. **Never calls run tools** (`log_run_event`, `request_gate`, `complete_run_task`, …). When a
   human decision is needed it reports `needs_gate` and stops; the task runner opens the gate.
4. **Acts on an approval only with `--gate <gateRef>`**, and only if `activeRun.approvedGate`
   has that `ref`, `step` equal to `test` and `attempt` equal to `activeRun.attempt`. Otherwise
   it reports `failed` with reason `gate_mismatch` and does nothing.
5. **Ends with exactly one result line** as its final output, a single line of JSON:
   `ZAO_RESULT {"command":"test-task","code":"<CODE>","status":"ok"|"failed"|"needs_gate","summary":"<≤300 chars>","data":{"testRunRef","headSha","failureSummary"?},"gate"?:{"kind","prompt","payload"},"error"?:{"reason","lastError"}}`.
6. **Keeps the Cairn token out of repo commands.** If `CAIRN_TOKEN` is set in the environment
   (test with `[ -n "$CAIRN_TOKEN" ]`, never echo it), run every repo command (checks, builds,
   package scripts, dev servers) as `env -u CAIRN_TOKEN <command>`.

`--autonomous` needs the Cairn provider and a task that is the run's in-flight entry
(`activeRun.baseBranch` is present). Otherwise report `failed` (reason `not_run_task`). Without
`--autonomous` the command never prints `ZAO_RESULT` and behaves as described below.

| Interactive point | With `--autonomous` |
|---|---|
| Not on a task branch | Report `failed` (reason `not_on_task_branch`). |
| Which checks to run | `--profile quick` unless another profile is given: exactly `activeRun.checkNames`. |
| A check has no command | Record it as `error`, never `skip`. |
| Playwright cannot connect (visual check) | Record `visual` as `error` with the reason. |
| "Would you like me to fix these?" | Never asked. Report `failed` with the failures; the task runner's fix loop handles them. |
| Result | `ok` when every check passed; `failed` when any check failed or errored, with `data.failureSummary` (≤ 1,500 characters: check, test name, one-line excerpt per failure) and `error {reason: "checks_failed", lastError}`. |

## Relevant MCP Tools
- **Playwright** (`mcp__plugin_playwright_playwright__*`, from the Playwright plugin): Browser
  automation for visual testing and UX flow verification
- **Build tools**: Run linting, type checking, and build validation from config
- **Cairn** (provider `cairn` only): record the test run, upload screenshots as evidence, tick
  acceptance criteria

## Prerequisites Check

1. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `project.type` - determines if visual testing is relevant
     - `build.commands.lint` - lint command
     - `build.commands.typecheck` - type check command
     - `build.commands.build` - build command
     - `build.commands.test` - test command (the `unit` check)
     - `build.commands.e2e` and `build.commands.integration` - used by the `full` profile when set
     - `build.commands.dev` - dev server command
     - `build.dev_port` - port for Playwright testing
     - `git.default_branch` - for checking if on task branch
     - `milestone_mode.task_checks` and `milestone_mode.full_suite` - the `quick` and `full` profiles

2. **Check current branch**
   - Run `git branch --show-current`
   - If on `{git.default_branch}`, or not on a task branch per the `zao:pm-provider` skill's
     branch rule:

     **For technical users:**
     > "On `{git.default_branch}`. No task branch to test. Run `/zao:begin-task` first."

     **For non-technical users:**
     > "You're not working on a task. There's nothing to test. Run `/zao:begin-task TSK-XXX` to start a task first."

     - Stop execution
   - **Cairn:** `mcp__cairn__get_task_context { branch: "<current branch>" }` for the task code,
     acceptance criteria and `activeRun`.

3. **Check for uncommitted changes**
   - Run `git status --porcelain`
   - If there are changes:

     **For technical users:**
     > "Uncommitted changes detected. Committing before test run."

     **For non-technical users:**
     > "You have uncommitted changes. Let me save those first before testing."

     ```bash
     git add -A
     git commit -m "wip: save progress before testing"
     ```

## Test Process

1. **Announce testing start**

   **For technical users:**
   > "Running test suite..."

   **For non-technical users:**
   > "Running tests and checks on your work. This may take a minute..."

2. **Choose the profile**

   | Profile | Checks |
   |---|---|
   | `standard` (default) | Today's behaviour: lint, typecheck, unit, build (each only if its command is set), plus visual for UI project types |
   | `quick` | Inside a milestone run: exactly `activeRun.checkNames`. Otherwise `milestone_mode.task_checks`, default lint, typecheck and unit, keeping only those with a command. |
   | `full` | `milestone_mode.full_suite`, default lint, typecheck, unit and build where their commands are set, then `e2e`, plus `visual` for UI project types |

   Each check name maps to a command:

   | Check | Runs |
   |---|---|
   | `lint` | `build.commands.lint` |
   | `typecheck` | `build.commands.typecheck` |
   | `unit` | `build.commands.test` |
   | `build` | `build.commands.build` |
   | `e2e` | `build.commands.e2e` |
   | `integration` | `build.commands.integration` |
   | `visual` | The Playwright visual pass in step 4 |

   In `standard`, a check whose command is not set is skipped, as today. In `quick` and `full`,
   every named check must run: one with no command is recorded as `error`, never `skip`.
   Run long checks (`build`, `e2e`) with the Bash tool's `run_in_background` when they may exceed
   the 10-minute foreground limit, and wait for the completion notification.

3. **Run code quality checks**

   Run the profile's checks from `build.commands` in config, in the order below.

   a. **Linting** (if `build.commands.lint` is set)
      ```bash
      {build.commands.lint}
      ```

      **For technical users:**
      > "Lint: {PASS/FAIL - show issues if any}"

      **For non-technical users:**
      - If pass: "Code style checks passed."
      - If fail: "Found some code style issues that should be fixed."

   b. **Type checking** (if `build.commands.typecheck` is set)
      ```bash
      {build.commands.typecheck}
      ```

      **For technical users:**
      > "Types: {PASS/FAIL - show issues if any}"

      **For non-technical users:**
      - If pass: "Code consistency checks passed."
      - If fail: "Found some code consistency issues."

   c. **Unit tests** (if `build.commands.test` is set)
      ```bash
      {build.commands.test}
      ```

      **For technical users:**
      > "Tests: {X passed, Y failed, Z skipped}"

      **For non-technical users:**
      - If pass: "All automated tests passed."
      - If fail: "Some tests failed - this means something isn't working as expected."

   d. **Build check** (if `build.commands.build` is set)
      ```bash
      {build.commands.build}
      ```

      **For technical users:**
      > "Build: {PASS/FAIL}"

      **For non-technical users:**
      - If pass: "Build completed successfully."
      - If fail: "Build failed - there's something preventing the code from compiling."

   e. **Integration and E2E tests** (only when the profile names `integration` or `e2e`)
      ```bash
      {build.commands.integration}
      {build.commands.e2e}
      ```

      **For technical users:**
      > "E2E: {X passed, Y failed}"

      **For non-technical users:**
      - If pass: "The end-to-end user flows work."
      - If fail: "Some user flows don't work as expected yet."

   Keep, for each check: its status (`pass`, `fail`, `skip` or `error`), a one-line summary,
   the counts the reporter prints (passed, failed, skipped) and the duration, plus every failing
   test's name, file and a short excerpt of the error.

4. **Run visual/UX tests with Playwright** (if applicable)

   Only run this section if `project.type` is: web-app, desktop-app, mobile-app, or fullstack
   (and, for `quick` and `full`, only when the profile names `visual`)

   a. **Start the dev server** (if `build.commands.dev` is set)
      - Start `{build.commands.dev}` with the Bash tool's `run_in_background`
      - Wait for it to be ready (check port `{build.dev_port}`)

   b. **Navigate to the app**
      - Use `mcp__plugin_playwright_playwright__browser_navigate` to go to `http://127.0.0.1:{build.dev_port}`

   c. **Take screenshots of the changes**
      - Use `mcp__plugin_playwright_playwright__browser_snapshot` to understand the page
      - Use `mcp__plugin_playwright_playwright__browser_take_screenshot` to capture visuals

   d. **Test key interactions** (based on what the task implemented)
      - Use Playwright tools to click buttons, fill forms, navigate
      - Verify expected behaviors work

   e. **Close browser when done**
      - Use `mcp__plugin_playwright_playwright__browser_close`
      - Stop the dev server you started (`TaskStop` on its background shell). Stop only shells
        this command started.

5. **Cairn: record the evidence** (provider `cairn` only; skip for Lakar and Note&Task)

   a. **Upload screenshots first**, before anything cleans `.playwright-mcp/`. For each
      screenshot worth keeping (at most a handful: the changed screens and any failure):
      - `mcp__cairn__create_attachment_upload { code, filename, contentType: "image/png", sizeBytes: <wc -c < file>, clientKey: "<CODE>:upload:<sha7>:<hash8 of filename>" }`
      - run the returned `curl` command with the file's path
      - `mcp__cairn__complete_attachment_upload { attachmentId }`, and keep the `attachmentId`

   b. **Record the test run**:
      `mcp__cairn__record_test_run { code, scope: "task", profile, trigger: "run_task" with --autonomous else "test_task", commitSha: <git rev-parse HEAD>, branch: <current branch>, checks: [{name, status, summary, counts, durationMs}], failures: [{check, name, file, excerpt}] (at most 50, excerpts ≤ 1,000 characters), attachmentIds, clientKey: "<CODE>:test:<sha7>:<profile>:<iteration>" }`,
      where `iteration` is `activeRun.fixIteration` inside a run and `0` otherwise. If Cairn
      answers `idempotency_conflict` (the same key was used for a different result at this
      commit), increase `iteration` by one and retry. Keep the returned `ref` (e.g. `QAA-14-T3`).

   c. **Tick acceptance criteria** a passing test proves:
      `mcp__cairn__mark_acceptance_criteria { code, items: [{ac: "AC2", done: true, evidence: "<test name> (<test-run ref>)"}] }`.
      Untick (`done: false`) a criterion that was ticked before and whose test now fails.

6. **Report results**

   With `--autonomous`, print only the compact technical table below, then the `ZAO_RESULT` line
   (`data` `{testRunRef, headSha, failureSummary}`) as the final output.

   **For technical users:**

   ---

   **Test Results** (profile: {profile})

   | Check | Status | Details |
   |-------|--------|---------|
   | Lint | {PASS/FAIL} | {issue count or "clean"} |
   | Types | {PASS/FAIL} | {issue count or "clean"} |
   | Tests | {PASS/FAIL} | {X/Y passed} |
   | Build | {PASS/FAIL} | {details} |
   | E2E | {PASS/FAIL/N/A} | {X/Y passed} |
   | Visual | {PASS/FAIL/N/A} | {notes} |

   {If failures, list specific issues}

   {Cairn: "Recorded as {test-run ref}; AC {done}/{total}."}

   ---

   **For non-technical users:**

   ---

   **Test Results**

   **Code Quality:**
   - {Linting result in plain language}
   - {Type checking result in plain language}
   - {Build result in plain language}

   **Automated Tests:**
   - {Test results in plain language}

   **Visual Testing:** (if applicable)
   - {Summary of what was tested}
   - {Any issues observed}

   {If screenshots taken: "Screenshots saved for your review."}

   ---

7. **Provide recommendations**

   With `--autonomous`, skip this step (never ask).

   **If all tests pass:**

   **For technical users:**
   > "All checks passed. Ready for `/zao:submit-task`."

   **For non-technical users:**
   > "All checks passed! Your work is ready for review."
   >
   > "Next step: `/zao:submit-task` to create a pull request."

   **If there are issues:**

   **For technical users:**
   > "Issues found:"
   > {List issues with file:line references}
   >
   > "Fix with `/zao:fix-issue` or address manually."

   **For non-technical users:**
   > "Some issues were found:"
   > - {List issues in simple terms}
   >
   > "Would you like me to fix these? Run `/zao:fix-issue <description>` for each issue, or I can try to fix them automatically if you'd like."

## Error Handling

- **Dev server won't start**:
  - Technical: "Dev server failed to start. Check `{build.commands.dev}` configuration. Error: {error}"
  - Non-technical: "The app isn't starting properly. This might be a build issue. Let me check..."

- **Tests timeout**:
  - Technical: "Test timeout exceeded. Possible infinite loop or async issue."
  - Non-technical: "The tests are taking too long. There might be a performance issue or infinite loop."

- **Playwright can't connect**:
  - Technical: "Playwright connection failed. Dev server may not be running on port {build.dev_port}."
  - Non-technical: "Can't open the browser for visual testing. The automated code checks still ran though."
  - In `quick` and `full`: record `visual` as `error`.

- **Command not configured**:
  - In `standard`: skip that check and note it wasn't run
    - Technical: "Skipping {check} - not configured in project.yaml"
    - Non-technical: (silently skip)
  - In `quick` and `full`: record the check as `error` ("no build.commands.<name> in project.yaml")

- **Cairn unreachable** (record or upload fails): report the results in chat, say they were not
  recorded, and retry once with the same `clientKey`. With `--autonomous`, report `failed`
  (reason `pm_unavailable`).

## Important

- Use commands from `build.commands` in config - never hardcode Nx or any specific tool
- Adjust all output language based on `user.mode`
- Only run visual tests for UI project types
- Use `build.dev_port` from config for Playwright
- Explain test results in terms appropriate to user mode
- Don't overwhelm non-technical users with technical output - summarize
- Be clear about what passed vs what needs attention
- Always provide a clear next step; with `--autonomous`, end with the single `ZAO_RESULT` line
- Cairn: upload screenshots before `.playwright-mcp/` is cleaned up, and never record a check that could not run as `skip` in the `quick` or `full` profile
