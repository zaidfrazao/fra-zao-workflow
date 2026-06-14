---
description: See your progress through the project setup phases
allowed-tools: Bash, Read, mcp__lakar__list_projects, mcp__lakar__list_clients
---

Show the current status of project setup and what needs to be done next.

## Steps

1. **Check which docs exist**

   Look for these files in the `docs/` directory:
   - `docs/PRD.md`
   - `docs/BRAND_GUIDE.md`
   - `docs/TESTING_STRATEGY.md`

2. **Check Lakar project status**

   - Use `mcp__lakar__list_clients` to see available teams
   - Use `mcp__lakar__list_projects` to check if a project has been created for this work

3. **Present status report**

   ---

   **Project Setup Status**

   | Phase | Status | Command |
   |-------|--------|---------|
   | Product Requirements | {Done/Not started} | `/fra:prd` |
   | Brand Guide | {Done/Not started/Waiting on PRD} | `/fra:brand` |
   | Testing Strategy | {Done/Not started/Waiting on PRD + Brand} | `/fra:testing` |
   | Lakar Project | {Done/Not started/Waiting on all docs} | `/fra:lakar` |

   ---

4. **Provide next step recommendation**

   Based on what's missing, recommend the next command:

   - If no PRD: "Start by defining what you're building. Run `/fra:prd`"
   - If PRD exists but no brand guide: "Next, define the visual and UX approach. Run `/fra:brand`"
   - If PRD + brand exist but no testing: "Next, the testing strategy will be generated. Run `/fra:testing`"
   - If all docs exist but no Lakar project: "All planning docs are ready! Run `/fra:lakar` to create your Lakar project"
   - If everything done: "Project setup is complete! You can update any doc with `/fra:update-prd`, `/fra:update-brand`, or `/fra:update-testing`"

5. **Show doc summaries (if they exist)**

   For each existing doc, show a brief summary:
   - PRD: Product name, vision statement, number of features defined
   - Brand Guide: Design system summary, key patterns
   - Testing Strategy: Types of testing planned

## Important

- This command is informational only - it doesn't create or modify anything
- Use friendly, clear language
- Always end with a specific next action
