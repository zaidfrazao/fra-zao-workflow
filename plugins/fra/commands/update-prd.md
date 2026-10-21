---
description: Update the existing PRD based on new information or feedback
allowed-tools: AskUserQuestion, mcp__pal__chat, mcp__pal__consensus, mcp__tavily__tavily_search, Read, Write, Edit, Skill, mcp__cairn__list_tasks
---

Update the existing Product Requirements Document with new information or refinements.

## Relevant MCP Tools
- **Zen Chat**: Discuss and refine changes collaboratively
- **Zen Consensus**: Get perspectives on significant changes
- **Tavily**: Research if updates require new information

## Prerequisites Check

1. **Check if PRD exists**
   - Look for `docs/PRD.md`
   - If not found: "No PRD exists yet. Run `/fra:prd` to create one first."

2. **Read the current PRD**
   - Load the full document to understand current state

## Update Process

### Step 1: Understand What Needs Changing

Use `AskUserQuestion` to understand the update:

- "What would you like to update in the PRD?"
- Present options:
  1. Add new features
  2. Modify existing features
  3. Update technical considerations
  4. Refine user segments
  5. Adjust success metrics
  6. Update assumptions or risks
  7. Other (describe)

### Step 2: Gather Details

Based on their selection, ask targeted follow-up questions:

**For new features:**
- What is the feature?
- Why is it needed now?
- What's the priority (must-have vs nice-to-have)?
- What are the acceptance criteria?

**For modifying features:**
- Which feature needs changes?
- What specifically needs to change?
- Does this affect the acceptance criteria?

**For technical changes:**
- What technical aspect is changing?
- Why the change?
- Does this affect any features?

Use `mcp__pal__chat` to help think through implications of changes.

For significant changes, use `mcp__pal__consensus` to evaluate the decision.

### Step 3: Impact Analysis

Before making changes, analyze impact:

- Does this change affect the Brand Guide?
- Does this change affect the Testing Strategy?
- Does this change affect existing tasks in the project-management app?

**Finding affected tasks (Cairn).** Resolve the PM provider with the `zao:pm-provider` skill
(Skill tool; it ships with the zao plugin) before the first PM call, and use its mapping
(`pm-mapping.md`) for every PM call below. If the provider is `cairn`, list the tasks linked to
each changed feature: for every PRD heading anchor the update touches (e.g. `#rule-form`), call
`mcp__cairn__list_tasks { projectIdentifier: <project_management.project_identifier>, docRef: "docs/PRD.md#<anchor>" }`
and collect the codes, titles and statuses. For Lakar and Note&Task, which do not link tasks to
PRD sections, judge the impact from the feature names as before.

Warn the user if updates might cascade:
> "This change may also require updates to:
> - Brand Guide: {If visual/UX implications}
> - Testing Strategy: {If new testing needs}
> - Existing tasks: {If scope change affects existing work; for Cairn, list the affected task codes, titles and statuses found above}
>
> After updating the PRD, consider running `/fra:update-brand` or `/fra:update-testing` if needed."

### Step 4: Apply Updates

Use the `Edit` tool to make targeted changes to `docs/PRD.md`:

- Update the relevant sections
- Update the "Last Updated" date in Document History
- Add a changelog entry if significant

For significant additions, maintain document structure and formatting.

### Step 5: Confirm Changes

Present a summary of what was changed:

---

**PRD Updated!**

**Changes Made:**
- {List of changes}

**Sections Modified:**
- {List of sections}

**Potential Cascade Effects:**
- {Any downstream docs that may need updates}

The updated document is at `docs/PRD.md`

---

## Important

- Preserve the existing document structure
- Don't remove information without explicit confirmation
- Track changes in the document history
- Warn about cascade effects to other documents
- For major overhauls, suggest creating a fresh PRD instead
