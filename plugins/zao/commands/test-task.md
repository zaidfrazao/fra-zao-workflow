---
description: Run automated tests and checks on your work before submitting
allowed-tools: mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_close, mcp__playwright__browser_wait_for, mcp__playwright__browser_hover, mcp__playwright__browser_evaluate, Bash, Read
---

Run automated tests and checks on the current task.

## Relevant MCP Tools
- **Playwright**: Browser automation for visual testing and UX flow verification
- **Build tools**: Run linting, type checking, and build validation from config

## Prerequisites Check

1. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `project.type` - determines if visual testing is relevant
     - `build.commands.lint` - lint command
     - `build.commands.typecheck` - type check command
     - `build.commands.build` - build command
     - `build.commands.test` - test command
     - `build.commands.dev` - dev server command
     - `build.dev_port` - port for Playwright testing
     - `git.default_branch` - for checking if on task branch

2. **Check current branch**
   - Run `git branch --show-current`
   - If on `{git.default_branch}`:

     **For technical users:**
     > "On `{git.default_branch}`. No task branch to test. Run `/zao:begin-task` first."

     **For non-technical users:**
     > "You're not working on a task. There's nothing to test. Run `/zao:begin-task TSK-XXX` to start a task first."

     - Stop execution

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

2. **Run code quality checks**

   Run these commands from `build.commands` in config. Skip any that are empty/null.

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

3. **Run visual/UX tests with Playwright** (if applicable)

   Only run this section if `project.type` is: web-app, desktop-app, mobile-app, or fullstack

   a. **Start the dev server** (if `build.commands.dev` is set)
      ```bash
      {build.commands.dev} &
      ```
      - Wait for it to be ready (check port `{build.dev_port}`)

   b. **Navigate to the app**
      - Use `mcp__playwright__browser_navigate` to go to `http://127.0.0.1:{build.dev_port}`

   c. **Take screenshots of the changes**
      - Use `mcp__playwright__browser_snapshot` to understand the page
      - Use `mcp__playwright__browser_take_screenshot` to capture visuals

   d. **Test key interactions** (based on what the task implemented)
      - Use Playwright tools to click buttons, fill forms, navigate
      - Verify expected behaviors work

   e. **Close browser when done**
      - Use `mcp__playwright__browser_close`
      - Stop the dev server

4. **Report results**

   **For technical users:**

   ---

   **Test Results**

   | Check | Status | Details |
   |-------|--------|---------|
   | Lint | {PASS/FAIL} | {issue count or "clean"} |
   | Types | {PASS/FAIL} | {issue count or "clean"} |
   | Tests | {PASS/FAIL} | {X/Y passed} |
   | Build | {PASS/FAIL} | {details} |
   | Visual | {PASS/FAIL/N/A} | {notes} |

   {If failures, list specific issues}

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

5. **Provide recommendations**

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

- **Command not configured**:
  - Skip that check and note it wasn't run
  - Technical: "Skipping {check} - not configured in project.yaml"
  - Non-technical: (silently skip)

## Important

- Use commands from `build.commands` in config - never hardcode Nx or any specific tool
- Adjust all output language based on `user.mode`
- Only run visual tests for UI project types
- Use `build.dev_port` from config for Playwright
- Explain test results in terms appropriate to user mode
- Don't overwhelm non-technical users with technical output - summarize
- Be clear about what passed vs what needs attention
- Always provide a clear next step
