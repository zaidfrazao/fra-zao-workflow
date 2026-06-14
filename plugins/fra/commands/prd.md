---
description: Define the product requirements document through guided questions
allowed-tools: AskUserQuestion, mcp__pal__planner, mcp__pal__chat, mcp__pal__consensus, mcp__tavily__tavily_search, mcp__tavily__tavily_extract, Read, Write, Bash
---

Create a comprehensive Product Requirements Document (PRD) through guided discovery.

## Relevant MCP Tools
- **Zen Planner**: Structure the PRD development process
- **Zen Chat**: Brainstorm and refine ideas collaboratively
- **Zen Consensus**: Get multiple perspectives on key decisions
- **Tavily**: Research competitors, market patterns, best practices

## Prerequisites Check

1. **Check if PRD already exists**
   - Look for `docs/PRD.md`
   - If exists, ask: "A PRD already exists. Would you like to start fresh (this will replace it) or update it instead? For updates, use `/fra:update-prd`"

2. **Ensure docs directory exists**
   ```bash
   mkdir -p docs
   ```

## Discovery Process

Guide the user through each section using `AskUserQuestion`. Use Zen tools to help ideate and Tavily to research where relevant.

### Section 1: Vision & Problem

Ask questions to understand:
- What is the product/project name?
- What problem does it solve?
- Who experiences this problem?
- Why is now the right time to build this?

Use `mcp__pal__chat` to help refine the vision statement if the user's initial response is vague.

### Section 2: Target Users

Ask questions to define user segments:
- Who are the primary users?
- Who are secondary users (if any)?
- What are their key characteristics?
- What are their goals and pain points?

Use `mcp__tavily__tavily_search` to research user behavior patterns in this domain if helpful.

### Section 3: Features & Requirements

Ask questions to define what will be built:
- What are the core features (must-haves)?
- What are nice-to-have features?
- What are explicit non-goals (what you're NOT building)?

For each core feature, dig deeper:
- What does success look like for this feature?
- What are the acceptance criteria?

Use `mcp__pal__consensus` for complex feature decisions where multiple approaches exist.

### Section 4: Technical Considerations

Ask questions about technical constraints:
- Are there specific technologies required or preferred?
- Are there integration requirements?
- What are the performance/scale expectations?
- Security or compliance requirements?

Use `mcp__tavily__tavily_search` to research technical approaches if the domain is unfamiliar.

### Section 5: Success Metrics

Ask questions about measuring success:
- How will you know if this product is successful?
- What are the key metrics to track?
- What are the initial targets?

### Section 6: Assumptions & Risks

Ask questions to surface risks:
- What assumptions are you making?
- What could go wrong?
- What dependencies exist?

## Document Generation

After gathering all information:

1. **Use Zen Planner to structure the content**
   - Organize features by priority
   - Ensure acceptance criteria are clear and testable
   - Identify gaps and ask follow-up questions if needed

2. **Generate the PRD**

   Create `docs/PRD.md` with this structure:

   ```markdown
   # {Product Name} - Product Requirements Document

   ## Vision
   {Clear vision statement}

   ## Problem Statement
   {What problem this solves and why it matters}

   ## Target Users

   ### Primary Users
   {Description, goals, pain points}

   ### Secondary Users (if applicable)
   {Description, goals, pain points}

   ## Features

   ### Core Features (Must-Have)

   #### Feature 1: {Name}
   **Description:** {What it does}
   **User Value:** {Why users need it}
   **Acceptance Criteria:**
   - [ ] {Criterion 1}
   - [ ] {Criterion 2}

   {Repeat for each core feature}

   ### Nice-to-Have Features
   {List with brief descriptions}

   ### Non-Goals
   {What we're explicitly NOT building and why}

   ## Technical Considerations
   - **Technology Preferences:** {Stack preferences}
   - **Integrations:** {Required integrations}
   - **Performance Requirements:** {Scale/speed expectations}
   - **Security/Compliance:** {Requirements}

   ## Success Metrics
   | Metric | Target | How Measured |
   |--------|--------|--------------|
   | {Metric 1} | {Target} | {Method} |

   ## Assumptions
   - {Assumption 1}
   - {Assumption 2}

   ## Risks
   | Risk | Likelihood | Impact | Mitigation |
   |------|------------|--------|------------|
   | {Risk 1} | {H/M/L} | {H/M/L} | {Plan} |

   ## Document History
   - **Created:** {Date}
   - **Last Updated:** {Date}
   ```

3. **Present summary to user**

   ---

   **PRD Created!**

   **{Product Name}**

   - **Vision:** {One-line vision}
   - **Core Features:** {Count} defined
   - **Target Users:** {Primary user type}

   The full document is saved at `docs/PRD.md`

   **Next step:** Define your brand and UX approach with `/fra:brand`

   ---

## Important

- Ask questions conversationally, not as a rigid form
- Use Zen tools to help the user think through complex decisions
- Use Tavily to bring in external research where valuable
- The PRD should be detailed enough to drive development but not overly verbose
- Acceptance criteria should be specific and testable
