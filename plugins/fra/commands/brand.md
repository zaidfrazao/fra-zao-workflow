---
description: Define the brand and UX guide through guided questions
allowed-tools: AskUserQuestion, mcp__pal__planner, mcp__pal__chat, mcp__pal__consensus, mcp__tavily__tavily_search, mcp__tavily__tavily_extract, Read, Write, Bash
---

Create a comprehensive Brand and UX Guide through guided discovery.

## Relevant MCP Tools
- **Zen Planner**: Structure the brand guide development
- **Zen Chat**: Brainstorm design directions collaboratively
- **Zen Consensus**: Get perspectives on design decisions
- **Tavily**: Research design patterns, competitor approaches, UI trends

## Prerequisites Check

1. **Check if PRD exists**
   - Look for `docs/PRD.md`
   - If not found: "The PRD should be created first so the brand guide aligns with the product vision. Run `/fra:prd` first."
   - If found: Read it to understand the product context

2. **Check if brand guide already exists**
   - Look for `docs/BRAND_GUIDE.md`
   - If exists, ask: "A brand guide already exists. Would you like to start fresh or update it instead? For updates, use `/fra:update-brand`"

3. **Read project configuration**
   - Load `.claude/project.yaml` to determine:
     - `user.mode` - technical or non-technical (affects language used)
     - `project.type` - determines if full or minimal template
     - `docs.brand_template` - explicit template preference (full, minimal, none)

   - If `docs.brand_template` is "none":
     > "Brand guide is disabled for this project. If you'd like to create one anyway, update `docs.brand_template` in `.claude/project.yaml`"
     - Stop execution

4. **Determine template type**
   - Use **minimal template** if:
     - `docs.brand_template` is "minimal", OR
     - `project.type` is: api, cli, or library
   - Use **full template** if:
     - `docs.brand_template` is "full", OR
     - `project.type` is: web-app, desktop-app, mobile-app, or fullstack

## Discovery Process

Read the PRD first to understand the product, then guide the user through brand decisions using `AskUserQuestion`.

**Adjust language based on `user.mode`:**
- **Technical**: Use design terminology freely
- **Non-technical**: Use simple language, explain concepts

---

## MINIMAL TEMPLATE (for APIs, CLIs, Libraries)

### Section 1: Brand Personality

Ask questions to understand the brand voice:
- What three words best describe how this project should feel to users?
- How should documentation and messages communicate? (formal, casual, friendly, technical)

### Section 2: Tone of Voice

Ask questions about written content:
- How should error messages feel? (apologetic, matter-of-fact, helpful)
- Any words or phrases to use or avoid?

### Document Generation (Minimal)

Create `docs/BRAND_GUIDE.md`:

```markdown
# {Product Name} - Brand Guide

## Brand Personality

### Core Attributes
- **Personality:** {3 key words}
- **Communication Style:** {How the product communicates}

## Tone of Voice

### Writing Style
- **Formality:** {Formal/Casual/Friendly/Technical}
- **Perspective:** {First person/Second person}

### Content Guidelines
- **Do:** {List of guidelines}
- **Don't:** {List of anti-patterns}

### Message Examples
| Context | Example |
|---------|---------|
| Success message | {Example} |
| Error message | {Example} |
| Help text | {Example} |

## Document History
- **Created:** {Date}
- **Last Updated:** {Date}
```

---

## FULL TEMPLATE (for Web Apps, Desktop Apps, Mobile Apps)

### Section 1: Brand Personality

Ask questions to understand the brand voice:

**For technical users:**
- If the product were a person, how would you describe their personality?
- What emotions should users feel when using the product?
- What three words best describe the brand?
- Are there brands (in any industry) whose style you admire?

**For non-technical users:**
- Imagine your product as a person helping someone. What's their personality like?
- How should people feel when they use this? (calm, excited, confident, etc.)
- Give me three words that describe the vibe you want
- Are there any apps or websites whose look you really like?

Use `mcp__tavily__tavily_search` to research cited brand examples.

### Section 2: Visual Identity

Ask questions about visual direction:

**For technical users:**
- Do you have existing brand colors, or should we define them?
- What mood should the color palette convey? (professional, playful, calm, energetic, etc.)
- Any colors to avoid?
- Typography preference? (modern/clean, classic/serif, playful/rounded, technical/monospace)

**For non-technical users:**
- Do you already have colors picked out, or should we figure those out?
- What feeling should the colors give? (serious and professional, fun and bright, calm and relaxing, etc.)
- Any colors you definitely don't want?
- What style of text do you prefer? (clean and modern, traditional and elegant, friendly and rounded)

Use `mcp__pal__chat` to suggest color palettes based on their mood description.

Research with Tavily:
- Look up color psychology for their target mood
- Find examples of similar products' visual approaches

### Section 3: Component Patterns

Ask questions about UI components:

**For technical users:**
- What's the density preference? (spacious/breathing room vs compact/information-dense)
- Corner style preference? (sharp, slightly rounded, very rounded)
- Should it feel minimal or feature-rich?
- Any specific UI libraries or frameworks you want to use or match?

**For non-technical users:**
- Do you prefer lots of white space or more compact layouts?
- Should buttons and boxes have sharp corners, slightly rounded, or very rounded?
- Should the design be simple with fewer things on screen, or show more options at once?

Use `mcp__tavily__tavily_search` to research component libraries and design systems relevant to their tech stack (from PRD).

### Section 4: Interaction Patterns

Ask questions about how the product feels to use:

**For technical users:**
- Should interactions feel snappy/immediate or smooth/animated?
- How important is progressive disclosure vs showing everything upfront?
- Any specific interaction patterns you want to follow? (drag-and-drop, keyboard shortcuts, etc.)

**For non-technical users:**
- Should things happen instantly when clicked, or have smooth animations?
- Should the interface show everything at once, or reveal things step by step?

### Section 5: Accessibility

Ask questions about accessibility requirements:

**For technical users:**
- What accessibility standard should we target? (WCAG 2.1 AA is typical)
- Any specific accessibility considerations for your user base?

**For non-technical users:**
- How important is it that the product works well for people with disabilities? (This affects things like color contrast and screen reader support)
- Will any of your users have vision, hearing, or mobility challenges?

### Section 6: Tone of Voice

Ask questions about written content:

**For technical users:**
- How should the product speak to users? (formal, casual, friendly, professional)
- Any words or phrases to use or avoid?
- How should error messages feel? (apologetic, matter-of-fact, helpful)

**For non-technical users:**
- How should the product talk to people? (like a professional colleague, like a friendly helper, etc.)
- Are there any words you want to use or avoid?
- When something goes wrong, how should the message feel? (sorry and apologetic, just the facts, helpful suggestions)

## Document Generation (Full)

After gathering all information:

1. **Use Zen Planner to organize the content**
   - Ensure consistency across sections
   - Fill in sensible defaults for anything not explicitly covered

2. **Generate the Brand Guide**

   Create `docs/BRAND_GUIDE.md` with this structure:

   ```markdown
   # {Product Name} - Brand & UX Guide

   ## Brand Personality

   ### Core Attributes
   - **Personality:** {3 key words}
   - **Emotional Response:** {What users should feel}
   - **Brand Voice:** {How the product communicates}

   ### Inspiration
   {Brands/products that inspire this direction and why}

   ## Visual Identity

   ### Color Palette

   #### Primary Colors
   | Name | Hex | Usage |
   |------|-----|-------|
   | Primary | {#hex} | Main actions, key UI elements |
   | Secondary | {#hex} | Supporting elements |

   #### Semantic Colors
   | Name | Hex | Usage |
   |------|-----|-------|
   | Success | {#hex} | Positive feedback, completion |
   | Warning | {#hex} | Caution states |
   | Error | {#hex} | Errors, destructive actions |
   | Info | {#hex} | Informational states |

   #### Neutral Colors
   | Name | Hex | Usage |
   |------|-----|-------|
   | Background | {#hex} | Page backgrounds |
   | Surface | {#hex} | Cards, elevated elements |
   | Border | {#hex} | Dividers, borders |
   | Text Primary | {#hex} | Main text |
   | Text Secondary | {#hex} | Supporting text |

   ### Typography

   #### Font Families
   - **Headings:** {Font name}
   - **Body:** {Font name}
   - **Monospace:** {Font name} (for code/technical content)

   #### Scale
   | Level | Size | Weight | Usage |
   |-------|------|--------|-------|
   | H1 | {size} | {weight} | Page titles |
   | H2 | {size} | {weight} | Section headers |
   | H3 | {size} | {weight} | Subsections |
   | Body | {size} | {weight} | Main content |
   | Small | {size} | {weight} | Captions, labels |

   ### Spacing & Layout

   - **Base unit:** {4px/8px}
   - **Density:** {Spacious/Comfortable/Compact}
   - **Border radius:** {None/Small/Medium/Large}
   - **Max content width:** {Width for readability}

   ## Component Patterns

   ### Buttons
   - **Primary:** {Description - when to use}
   - **Secondary:** {Description}
   - **Tertiary/Ghost:** {Description}
   - **Destructive:** {Description}

   ### Forms
   - **Input style:** {Description}
   - **Validation approach:** {Inline/On submit}
   - **Label position:** {Above/Beside/Floating}

   ### Cards & Containers
   - **Elevation:** {Flat/Subtle shadow/Pronounced shadow}
   - **Borders:** {Visible/Subtle/None}

   ### Navigation
   - **Primary navigation:** {Description}
   - **Secondary navigation:** {Description}

   ## Interaction Patterns

   ### Animation & Motion
   - **Overall feel:** {Snappy/Smooth/Minimal}
   - **Transition duration:** {Fast: Xms / Normal: Xms / Slow: Xms}
   - **Easing:** {Preferred easing function}

   ### Feedback Patterns
   - **Loading states:** {Skeletons/Spinners/Progress bars}
   - **Success feedback:** {Toast/Inline/Modal}
   - **Error handling:** {How errors are presented}

   ### Progressive Disclosure
   - **Approach:** {Show all vs reveal progressively}
   - **Patterns used:** {Accordions/Tabs/Modals/Drawers}

   ## Accessibility

   ### Standards
   - **Target:** {WCAG 2.1 AA/AAA}
   - **Color contrast:** Minimum {4.5:1 for text}

   ### Requirements
   - {Keyboard navigation support}
   - {Screen reader compatibility}
   - {Focus indicators}
   - {Reduced motion support}

   ## Tone of Voice

   ### Writing Style
   - **Formality:** {Formal/Casual/Friendly}
   - **Perspective:** {First person/Second person}

   ### Content Guidelines
   - **Do:** {List of guidelines}
   - **Don't:** {List of anti-patterns}

   ### UI Copy Examples
   | Context | Good | Avoid |
   |---------|------|-------|
   | Empty state | {Example} | {Example} |
   | Error message | {Example} | {Example} |
   | Success message | {Example} | {Example} |

   ## Document History
   - **Created:** {Date}
   - **Last Updated:** {Date}
   ```

3. **Present summary to user**

   **For technical users:**

   ---

   **Brand Guide Created!**

   **{Product Name}** brand identity:
   - **Personality:** {3 words}
   - **Visual Style:** {Brief description}
   - **Interaction Feel:** {Brief description}

   The full document is saved at `docs/BRAND_GUIDE.md`

   **Next step:** Generate your testing strategy with `/fra:testing`

   ---

   **For non-technical users:**

   ---

   **Your Brand Guide is Ready!**

   Here's what we defined for **{Product Name}**:
   - **Personality:** {3 words in simple terms}
   - **Look:** {Brief, simple description}
   - **Feel:** {Brief, simple description}

   This is saved and will guide how everything looks and feels.

   **Next step:** Type `/fra:testing` to set up how we'll test everything works correctly.

   ---

## Important

- Reference the PRD throughout to ensure alignment
- Ask questions conversationally, showing how answers connect to the product
- Use Tavily to bring in design research and examples
- Provide sensible defaults where the user doesn't have strong opinions
- Adjust language complexity based on user.mode setting
- The minimal template is appropriate for non-UI projects - don't force UI patterns on CLIs/APIs
