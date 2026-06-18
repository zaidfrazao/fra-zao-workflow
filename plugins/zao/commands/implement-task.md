---
description: Build the task according to the approved plan
allowed-tools: mcp__lakar__get_task, mcp__notetask__get_task, mcp__context7__resolve-library-id, mcp__context7__get-library-docs, mcp__tavily__tavily_search, mcp__tavily__tavily_extract, Bash, Read, Write, Edit, Glob, Grep
---

Implement the task that was planned in `/zao:begin-task`.

### Project management provider

This command only reads task context. Read `.claude/project.yaml` and resolve the provider: if a
`project_management:` block exists use `project_management.provider` (assume `lakar` if absent);
else if a legacy `lakar:` block exists the provider is `lakar`; else default to `lakar`. If the
provider is `notetask`, fetch the task with `mcp__notetask__get_task { code: CODE }` instead of
`mcp__lakar__get_task { id: CODE }`.

## Relevant MCP Tools
- **Context7**: Look up documentation for libraries (Electron, React, Colyseus, etc.)
- **Tavily**: Search for solutions, examples, or workarounds for specific problems

## Prerequisites Check

1. **Check current branch**
   - Run `git branch --show-current`
   - If on `main` or `develop`:
     > "You're not on a task branch. Please run `/zao:begin-task TSK-XXX` first to set up your task."
     - Stop execution

2. **Extract task context**
   - Parse the Lakar task code from branch name (e.g., `feature/TSK-123-title` → `TSK-123`)
   - Use `mcp__lakar__get_task` to fetch task details
   - Verify status is "In Progress"
     - If not, warn: "This task isn't marked as in progress. Did you run `/zao:begin-task` first?"

3. **Locate the plan**
   - Check conversation history for the plan created by `/zao:begin-task`
   - If no plan found in recent context:
     > "I don't see a recent plan for this task. Would you like me to review the task requirements and create a quick plan, or do you want to describe what needs to be built?"

## Implementation Process

1. **Announce start**
   > "Starting implementation for **{task-code}: {title}**"
   >
   > "I'll work through the plan step by step. Feel free to watch along and let me know if you have questions."

2. **Execute the plan**

   For each step in the plan:

   a. **Announce the step**
      > "**Step {n}:** {description of what's being done in simple terms}"

   b. **Research if needed**
      - Use `mcp__context7__resolve-library-id` and `mcp__context7__get-library-docs` for library documentation
      - Use `mcp__tavily__tavily_search` for general solutions or unfamiliar patterns

   c. **Navigate code intelligently**
      - Use `Grep` to locate specific functions/classes and understand file structure before editing
      - Use `Glob` to find relevant files, and `Grep` for references to understand dependencies
      - Use `Read` to inspect the files you'll change

   d. **Make changes**
      - Use the `Edit` tool for changes to existing files
      - Use the `Write` tool only for new files

   e. **Brief progress update**
      > "Done with step {n}. {One sentence about what was accomplished}"

3. **Commit progress periodically**
   - After completing logical chunks of work, commit:
     ```bash
     git add -A
     git commit -m "{type}: {descriptive message}

     🤖 Generated with Claude Code"
     ```
   - Use appropriate commit types from config (`feat:`, `fix:`, `refactor:`, etc.)

4. **Final commit and push**
   - After all implementation steps are complete, ensure everything is committed and pushed:
     ```bash
     git add -A
     git status --porcelain
     ```
   - If there are uncommitted changes:
     ```bash
     git commit -m "feat: complete {task-code} implementation

     🤖 Generated with Claude Code"
     git push origin $(git branch --show-current)
     ```
   - If already committed, just push:
     ```bash
     git push origin $(git branch --show-current)
     ```

5. **Completion summary**

   When all steps are done:

   ---

   **Implementation Complete**

   Here's what was built:
   - {Bullet point summary of changes in simple terms}

   **Files changed:**
   - {List of files, described by purpose not path}

   **Next steps:**
   - Review the changes and try them out
   - If you find any issues: `/zao:fix-issue <description>`
   - If you want adjustments: `/zao:adjust-feature <description>`
   - When ready to test: `/zao:test-task`
   - When ready for review: `/zao:submit-task`

   ---

## Error Handling

- **Build errors**: "Ran into a build issue: {simplified explanation}. Let me try to fix it..."
- **Missing dependencies**: "This needs a library that isn't installed. Let me add it..."
- **Unclear requirements**: "I'm not sure how to handle {x}. Could you clarify: {specific question}?"

## Important

- Explain what you're doing in simple terms as you go
- Don't use technical jargon without explanation
- Commit regularly so work isn't lost
- If stuck, ask for clarification rather than guessing
- End with clear next steps
