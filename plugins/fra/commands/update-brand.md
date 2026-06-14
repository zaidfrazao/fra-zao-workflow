---
description: Update the existing Brand Guide based on new information or feedback
allowed-tools: AskUserQuestion, mcp__pal__chat, mcp__pal__consensus, mcp__tavily__tavily_search, mcp__tavily__tavily_extract, Read, Write, Edit
---

Update the existing Brand & UX Guide with new information or refinements.

## Relevant MCP Tools
- **Zen Chat**: Discuss and refine design changes collaboratively
- **Zen Consensus**: Get perspectives on significant design decisions
- **Tavily**: Research design patterns, examples, or trends

## Prerequisites Check

1. **Check if Brand Guide exists**
   - Look for `docs/BRAND_GUIDE.md`
   - If not found: "No Brand Guide exists yet. Run `/fra:brand` to create one first."

2. **Read the current Brand Guide**
   - Load the full document to understand current state

3. **Read PRD for context**
   - Load `docs/PRD.md` to ensure changes align with product direction

## Update Process

### Step 1: Understand What Needs Changing

Use `AskUserQuestion` to understand the update:

- "What would you like to update in the Brand Guide?"
- Present options:
  1. Color palette
  2. Typography
  3. Spacing/layout
  4. Component patterns
  5. Interaction patterns
  6. Accessibility standards
  7. Tone of voice
  8. Other (describe)

### Step 2: Gather Details

Based on their selection, ask targeted follow-up questions:

**For color changes:**
- Which colors need to change?
- What's driving the change? (feedback, accessibility, rebrand)
- Show current colors and ask for new values or direction

**For typography:**
- Headings, body, or both?
- New font suggestions or just sizing changes?

**For component patterns:**
- Which components?
- What's the new pattern?
- Reference examples?

Use `mcp__pal__chat` to brainstorm alternatives.

Use `mcp__tavily__tavily_search` to research design patterns or find examples if helpful.

For significant visual changes, use `mcp__pal__consensus` to evaluate options.

### Step 3: Impact Analysis

Before making changes, analyze impact:

- Does this affect existing implemented components?
- Does this change accessibility compliance?
- Does this affect the Testing Strategy (visual testing baselines)?

Warn the user if updates have implications:
> "This change may affect:
> - Existing implementation: {If components already built}
> - Testing Strategy: {If visual testing needs updating}
> - Accessibility: {If contrast or standards affected}
>
> Consider reviewing `/fra:update-testing` after this update."

### Step 4: Apply Updates

Use the `Edit` tool to make targeted changes to `docs/BRAND_GUIDE.md`:

- Update the relevant sections
- Ensure consistency across related sections (e.g., if primary color changes, check all references)
- Update the "Last Updated" date in Document History

### Step 5: Confirm Changes

Present a summary of what was changed:

---

**Brand Guide Updated!**

**Changes Made:**
- {List of changes}

**Sections Modified:**
- {List of sections}

**Implementation Notes:**
- {Any notes about updating existing code}

**Potential Cascade Effects:**
- {Testing Strategy updates if visual testing affected}
- {Existing components that may need updates}

The updated document is at `docs/BRAND_GUIDE.md`

---

## Important

- Ensure changes maintain internal consistency (e.g., color references across sections)
- Check accessibility implications of visual changes
- Preserve the document structure
- Track changes in document history
- For major redesigns, consider creating a fresh Brand Guide instead
