---
description: Make adjustments or tweaks to the current implementation
allowed-tools: mcp__lakar__get_task, mcp__serena__find_symbol, mcp__serena__get_symbols_overview, mcp__serena__replace_symbol_body, mcp__serena__insert_after_symbol, mcp__serena__insert_before_symbol, mcp__serena__search_for_pattern, mcp__serena__find_referencing_symbols, mcp__serena__list_dir, mcp__serena__find_file, mcp__context7__resolve-library-id, mcp__context7__get-library-docs, mcp__tavily__tavily_search, mcp__tavily__tavily_extract, Bash, Read, Write, Edit, Glob, Grep
---

Make the adjustment: $ARGUMENTS

## Relevant MCP Tools
- **Serena**: Navigate and edit code using symbol-level operations
- **Context7**: Look up library documentation for implementation options
- **Tavily**: Research patterns, examples, or alternative approaches

## Prerequisites Check

1. **Validate argument**
   - If no argument provided:
     > "Please describe what you'd like changed. Example: `/zao:adjust-feature make the button bigger and change it to blue`"
     - Stop execution

2. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `git.default_branch` - for checking if on task branch
     - `commits.types.refactor` - commit type for adjustments (e.g., "refactor")
     - `commits.types.style` - commit type for visual changes (e.g., "style")
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

## Adjustment Process

1. **Acknowledge the request**

   **For technical users:**
   > "Adjusting: **{user's adjustment description}**"

   **For non-technical users:**
   > "Got it - you'd like to: **{user's adjustment description}**"
   >
   > "Let me make that change."

2. **Locate the relevant code**
   - Use `mcp__serena__search_for_pattern` or `mcp__serena__find_symbol` to find what needs changing
   - Use `mcp__serena__get_symbols_overview` to understand the file structure

3. **Research if needed**
   - Use `mcp__context7__get-library-docs` for library-specific implementations
   - Use `mcp__tavily__tavily_search` for patterns or examples

4. **Clarify if ambiguous**
   - If the request could be interpreted multiple ways:

     **For technical users:**
     > "Clarification needed: {option A} or {option B}?"

     **For non-technical users:**
     > "Just to make sure I understand - do you want {option A} or {option B}?"

   - Wait for clarification before proceeding

5. **Make the adjustment**
   - Use Serena's symbol-level editing for precise changes
   - Explain what you're changing

   **For technical users:**
   > "Modifying: {technical description}"

   **For non-technical users:**
   > "Making the change: {simple description}"

6. **Commit the change**

   Determine commit type based on nature of change:
   - Visual/UI changes → use `commits.types.style` (typically "style")
   - Behavioral/logic changes → use `commits.types.refactor` (typically "refactor")

   ```bash
   git add -A
   git commit -m "{commits.types.refactor or style}: {brief description of adjustment}

   {commits.footer}"
   ```

7. **Report completion**

   **For technical users:**

   ---

   **Adjusted**

   - **Change:** {what was modified}
   - **Files:** {list of files}

   **Next:** Test with `/zao:test-task`, more adjustments with `/zao:adjust-feature`, or fix issues with `/zao:fix-issue`.

   ---

   **For non-technical users:**

   ---

   **Done!**

   **What I changed:** {simple explanation of the adjustment}

   **What to do now:**
   - Take a look and see if it's what you wanted
   - If you want more adjustments: `/zao:adjust-feature <description>`
   - If something's broken: `/zao:fix-issue <description>`
   - When ready to test everything: `/zao:test-task`

   ---

## Handling Scope

If the adjustment request seems like significant new work beyond the original task:

**For technical users:**
> "This is significant scope expansion. Options:"
> "1. Include in current task (extends timeline)"
> "2. Create separate Lakar task"
> "Preference?"

**For non-technical users:**
> "This adjustment is quite a bit bigger than the original task. We have two options:"
>
> "1. **Add it anyway** - I can include it in this task, but it'll take longer"
> "2. **Make it a separate task** - We can create a new Lakar task for this and keep the current task focused"
>
> "What would you prefer?"

## Error Handling

- **Can't find what to change**:
  - Technical: "Unable to locate target code. Specify file or component name."
  - Non-technical: "I'm not sure where to make this change. Can you tell me more about where you're seeing {the thing they want changed}?"

- **Change might break things**:
  - Technical: "Change may affect: {components}. Proceed?"
  - Non-technical: "I can make this change, but it might affect {other feature}. Want me to proceed?"

- **Conflicting requirements**:
  - Technical: "Conflicts with existing requirement: {requirement}. Which takes priority?"
  - Non-technical: "This adjustment seems to conflict with {original requirement}. Which should take priority?"

## Important

- Adjustments are for tweaks and refinements, not bug fixes (use `/zao:fix-issue` for those)
- Always confirm understanding before making changes
- Keep changes focused - don't over-engineer
- Use `commits.types.style` for visual changes, `commits.types.refactor` for behavioral changes
- Use `commits.footer` from config
- Adjust all language based on `user.mode`
- Commit after each adjustment so work isn't lost
