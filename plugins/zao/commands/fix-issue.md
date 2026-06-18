---
description: Fix a bug or issue you've found in the current task
allowed-tools: mcp__lakar__get_task, mcp__notetask__get_task, mcp__context7__resolve-library-id, mcp__context7__get-library-docs, mcp__tavily__tavily_search, mcp__tavily__tavily_extract, mcp__pal__debug, Bash, Read, Write, Edit, Glob, Grep
---

Fix the issue: $ARGUMENTS

### Project management provider

This command only reads task context. Read `.claude/project.yaml` and resolve the provider: if a
`project_management:` block exists use `project_management.provider` (assume `lakar` if absent);
else if a legacy `lakar:` block exists the provider is `lakar`; else default to `lakar`. If the
provider is `notetask`, fetch the task with `mcp__notetask__get_task { code: CODE }` instead of
`mcp__lakar__get_task { id: CODE }`.

## Relevant MCP Tools
- **Context7**: Look up library documentation for correct usage
- **Tavily**: Search for error messages, known issues, or solutions
- **Zen Debug**: Systematic debugging for complex issues with root cause analysis

## Prerequisites Check

1. **Validate argument**
   - If no argument provided:
     > "Please describe the issue you've found. Example: `/zao:fix-issue the button doesn't change color when I hover over it`"
     - Stop execution

2. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `git.default_branch` - for checking if on task branch
     - `commits.types.bugfix` - commit type for fixes (e.g., "fix")
     - `commits.footer` - commit message footer

3. **Check current branch**
   - Run `git branch --show-current`
   - If on `{git.default_branch}`:

     **For technical users:**
     > "On `{git.default_branch}`. Start a task first with `/zao:begin-task TSK-XXX`."

     **For non-technical users:**
     > "You're not on a task branch. If you haven't started a task yet, run `/zao:begin-task TSK-XXX` first."

     - Stop execution

4. **Get task context**
   - Parse Lakar task code from branch name
   - Use `mcp__lakar__get_task` to fetch task details for context

## Fix Process

1. **Acknowledge the issue**

   **For technical users:**
   > "Investigating: **{user's issue description}**"

   **For non-technical users:**
   > "Got it - you're seeing: **{user's issue description}**"
   >
   > "Let me investigate and fix this."

2. **Investigate the issue**

   a. **Understand what's affected**
      - Use `Grep` to find relevant code and understand file structure
      - Use `Glob` to locate related files, and `Grep` for references to trace dependencies
      - Use `Read` to inspect the affected files

   b. **Research if needed**
      - Use `mcp__tavily__tavily_search` to look up error messages or similar issues
      - Use `mcp__context7__get-library-docs` if it might be a library usage issue

   c. **For complex issues, use Zen Debug**
      - If the issue isn't immediately clear, use `mcp__pal__debug` for systematic root cause analysis
      - This helps with tricky bugs, race conditions, or mysterious behavior

3. **Explain the problem**

   **For technical users:**
   > "Root cause: {technical explanation with code references}"

   **For non-technical users:**
   > "Found the issue: {simple explanation of what's wrong and why}"

4. **Apply the fix**
   - Use the `Edit` tool for precise changes
   - Explain what you're changing

   **For technical users:**
   > "Fix: {technical description of change}"

   **For non-technical users:**
   > "Fixing it by: {simple explanation}"

5. **Verify the fix**
   - If possible, run relevant tests or checks
   - Explain how the fix addresses the problem

6. **Commit the fix**

   Use the commit type from config (`commits.types.bugfix`, typically "fix"):

   ```bash
   git add -A
   git commit -m "{commits.types.bugfix}: {brief description of what was fixed}

   {commits.footer}"
   ```

7. **Report completion**

   **For technical users:**

   ---

   **Fixed**

   - **Issue:** {brief description}
   - **Cause:** {root cause}
   - **Fix:** {what was changed}
   - **Files:** {list of files modified}

   **Next:** `/zao:test-task` to verify, or `/zao:fix-issue` for more issues.

   ---

   **For non-technical users:**

   ---

   **Fixed!**

   **The problem was:** {simple explanation}

   **The fix:** {what was changed, in simple terms}

   **What to do now:**
   - Try it out and make sure it works as expected
   - If there are more issues: `/zao:fix-issue <description>`
   - If you want changes: `/zao:adjust-feature <description>`
   - When ready to test everything: `/zao:test-task`

   ---

## Error Handling

- **Can't reproduce/find the issue**:
  - Technical: "Unable to locate issue. Need more context: stack trace, steps to reproduce, or affected file."
  - Non-technical: "I'm having trouble finding where this issue comes from. Can you tell me more about: {specific questions - when it happens, what you clicked, what you expected}?"

- **Issue is in external code**:
  - Technical: "Issue in external dependency: {package}. Options: upgrade, patch, or workaround."
  - Non-technical: "This seems to be related to a library we're using, not our code. {Explain options: workaround, update, etc.}"

- **Fix might break other things**:
  - Technical: "Fix may affect: {list components}. Proceed?"
  - Non-technical: "I can fix this, but it might affect {other feature}. Want me to proceed, or should we think about this more carefully?"

## Important

- Always explain what was wrong and why, at the appropriate level for `user.mode`
- Don't just fix silently - help the user understand
- If you're unsure about the fix, say so and discuss options
- Use `commits.types.bugfix` from config for commit prefix (not hardcoded "fix:")
- Use `commits.footer` from config
- Adjust all language based on `user.mode`
- Commit the fix so it's not lost
