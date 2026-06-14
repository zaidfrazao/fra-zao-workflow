---
description: Update the existing Testing Strategy based on PRD or Brand Guide changes
allowed-tools: AskUserQuestion, mcp__pal__planner, mcp__tavily__tavily_search, Read, Write, Edit
---

Update the existing Testing Strategy based on changes to the PRD or Brand Guide.

## Relevant MCP Tools
- **Zen Planner**: Help restructure testing approach
- **Tavily**: Research testing tools or approaches if needed

## Prerequisites Check

1. **Check if Testing Strategy exists**
   - Look for `docs/TESTING_STRATEGY.md`
   - If not found: "No Testing Strategy exists yet. Run `/fra:testing` to create one first."

2. **Read current documents**
   - Load `docs/TESTING_STRATEGY.md` - current strategy
   - Load `docs/PRD.md` - for feature context
   - Load `docs/BRAND_GUIDE.md` - for visual/accessibility context

## Update Process

### Step 1: Understand What Needs Changing

Use `AskUserQuestion` to understand the update:

- "What's driving the testing strategy update?"
- Present options:
  1. PRD changed (new features, modified requirements)
  2. Brand Guide changed (visual testing updates needed)
  3. Tech stack changed (different testing tools needed)
  4. Coverage targets need adjustment
  5. CI/CD approach changed
  6. New testing requirements discovered
  7. Other (describe)

### Step 2: Analyze Changes

Based on the trigger:

**If PRD changed:**
- Compare current E2E test flows with PRD features
- Identify new flows that need tests
- Identify removed features whose tests can be removed
- Update acceptance criteria mappings

**If Brand Guide changed:**
- Update visual regression testing sections
- Update accessibility testing if standards changed
- Update component testing patterns

**If tech stack changed:**
- Use `mcp__tavily__tavily_search` to research new testing tools
- Update framework recommendations
- Update CI/CD integration approach

### Step 3: Regenerate or Edit

For minor updates:
- Use `Edit` tool to update specific sections

For significant changes (new features, major tech changes):
- Consider regenerating affected sections using `mcp__pal__planner`
- Maintain document structure while updating content

### Step 4: Apply Updates

Update `docs/TESTING_STRATEGY.md`:

- Update relevant sections
- Ensure E2E flows match current PRD features
- Ensure accessibility standards match Brand Guide
- Update "Last Updated" and "Derived From" versions in Document History

### Step 5: Confirm Changes

Present a summary:

---

**Testing Strategy Updated!**

**Changes Made:**
- {List of changes}

**Sections Modified:**
- {List of sections}

**E2E Test Flows:**
- Added: {New flows}
- Removed: {Deprecated flows}
- Modified: {Changed flows}

**Tool Changes:**
- {Any testing tool updates}

The updated document is at `docs/TESTING_STRATEGY.md`

**Note:** If tests are already implemented, you may need to update the actual test code to match this strategy.

---

## Important

- Keep the testing strategy aligned with current PRD and Brand Guide
- Update the "Derived From" reference to note which versions the strategy reflects
- The strategy should remain practical and implementable
- Flag if changes require updates to existing test implementations
