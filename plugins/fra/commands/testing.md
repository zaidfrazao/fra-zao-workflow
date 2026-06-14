---
description: Generate a testing strategy based on the PRD and brand guide
allowed-tools: AskUserQuestion, mcp__pal__planner, mcp__tavily__tavily_search, Read, Write, Bash
---

Generate a comprehensive Testing Strategy based on the PRD and Brand Guide.

## Relevant MCP Tools
- **Zen Planner**: Structure the testing strategy
- **Tavily**: Research testing tools and best practices for the tech stack

## Prerequisites Check

1. **Check if PRD exists**
   - Look for `docs/PRD.md`
   - If not found: "The PRD is required to generate a testing strategy. Run `/fra:prd` first."

2. **Check if Brand Guide exists**
   - Look for `docs/BRAND_GUIDE.md`
   - If not found: "The Brand Guide is required for visual/UX testing strategy. Run `/fra:brand` first."

3. **Check if testing strategy already exists**
   - Look for `docs/TESTING_STRATEGY.md`
   - If exists, ask: "A testing strategy already exists. Would you like to regenerate it or update it instead? For updates, use `/fra:update-testing`"

4. **Read project configuration**
   - Load `.claude/project.yaml` to get:
     - `user.mode` - technical or non-technical (affects language)
     - `project.type` - affects which testing types are relevant
     - `build.tool` - determines which test frameworks to recommend
     - `build.commands` - existing test commands configured
     - `build.dev_port` - for E2E testing

## Analysis Process

This command is mostly automated - read the PRD and Brand Guide to derive the testing strategy.

### Step 1: Analyze the PRD

Read `docs/PRD.md` and extract:
- Core features and their acceptance criteria
- Technical stack/preferences
- Performance requirements
- Security/compliance requirements
- User types and their key flows

### Step 2: Analyze the Brand Guide

Read `docs/BRAND_GUIDE.md` and extract:
- Accessibility requirements
- Interaction patterns that need testing
- Visual consistency requirements
- Responsive/cross-browser needs

### Step 3: Research Testing Tools

Use `mcp__tavily__tavily_search` to research appropriate testing tools based on `build.tool`:

**By build tool:**
- **npm/yarn/pnpm (Node.js)**: Jest, Vitest, Playwright, Cypress
- **nx**: Same as Node.js, with Nx test runners
- **cargo (Rust)**: Built-in `cargo test`, proptest for property testing
- **go**: Built-in `go test`, testify, ginkgo
- **python**: pytest, unittest, hypothesis
- **make**: Depends on underlying language

**By project type:**
- **web-app/fullstack**: E2E (Playwright/Cypress), visual regression, accessibility
- **api**: Integration tests, contract tests, load testing
- **cli**: Integration tests, snapshot testing
- **library**: Unit tests, property tests, doc tests
- **desktop-app**: E2E, visual regression, accessibility
- **mobile-app**: Device testing, E2E, visual regression

### Step 4: Confirm with User

Use `AskUserQuestion` to confirm a few key decisions.

**For technical users:**
- "Based on the PRD and your {build.tool} setup, I'm planning to use {framework} for unit tests. Does that work?"
- "For E2E testing, {tool} seems like a good fit. Any preferences?"
- "What's your target test coverage percentage? (e.g., 80%)"

**For non-technical users:**
- "I'll set up automatic testing using {framework} - this will catch bugs before they reach users. Sound good?"
- "For testing the actual interface, I recommend {tool}. It will simulate real users clicking through your app."
- "How thorough should testing be? (Very thorough takes longer but catches more issues)"

## Document Generation

Generate `docs/TESTING_STRATEGY.md` based on analysis:

```markdown
# {Product Name} - Testing Strategy

## Overview

This document defines the testing approach for {Product Name}, derived from the PRD and Brand Guide.

## Testing Pyramid

```
        /\
       /  \      E2E Tests (Critical user flows)
      /----\
     /      \    Integration Tests (API, component interactions)
    /--------\
   /          \  Unit Tests (Functions, components, utilities)
  --------------
```

### Distribution Target
- **Unit Tests:** {60-70%} of test coverage
- **Integration Tests:** {20-30%} of test coverage
- **E2E Tests:** {5-10%} of test coverage (critical paths only)

## Testing Types

### Unit Testing

**Framework:** {Framework based on build.tool}
**Command:** `{build.commands.test or default}`

**What to Test:**
- Pure functions and utilities
- Component rendering and state
- Data transformations
- Validation logic

**Coverage Target:** {X%}

**Conventions:**
- Test files: `*.test.{ext}` or `*.spec.{ext}`
- Location: Co-located with source files
- Naming: `describe('{UnitName}', () => { it('should {behavior}', ...) })`

### Integration Testing

**Framework:** {Framework based on build.tool}

**What to Test:**
- API endpoints
- Database operations
- Component interactions
- Service integrations

**Key Integration Points:**
{List derived from PRD technical considerations}

### End-to-End Testing

{Include this section only if project.type is: web-app, desktop-app, mobile-app, or fullstack}

**Framework:** {Playwright/Cypress based on research}
**Dev Server:** `{build.commands.dev}` on port `{build.dev_port}`

**Critical User Flows to Test:**
{Derived from PRD features - list the core user journeys}

1. **{Flow Name}**
   - Steps: {High-level steps}
   - Success Criteria: {From PRD acceptance criteria}

2. **{Flow Name}**
   - Steps: {High-level steps}
   - Success Criteria: {From PRD acceptance criteria}

{Continue for each critical flow}

### Visual Regression Testing

{Include this section only if project.type is: web-app, desktop-app, mobile-app, or fullstack}

**Tool:** {Playwright screenshots, Percy, Chromatic, etc.}

**What to Capture:**
- Key UI states for each major component
- Responsive breakpoints
- Light/dark themes (if applicable)
- Loading/error/empty states

**Baseline Management:**
- Baselines stored in: {Location}
- Update process: {How to update when intentional changes are made}

### Accessibility Testing

{Include this section only if project.type has UI}

**Standards Target:** {From Brand Guide - e.g., WCAG 2.1 AA}

**Automated Checks:**
- Tool: {axe-core, pa11y, etc.}
- Run: {On every component, in CI, etc.}

**Manual Checks Required:**
- Keyboard navigation for all interactive elements
- Screen reader testing for critical flows
- Color contrast verification
- Focus management

**Checklist:**
- [ ] All interactive elements are keyboard accessible
- [ ] Focus order is logical
- [ ] Images have appropriate alt text
- [ ] Form inputs have associated labels
- [ ] Error messages are announced to screen readers
- [ ] Sufficient color contrast (minimum {4.5:1})
- [ ] Content is readable at 200% zoom

### Performance Testing

{Adjust based on project type}

**Requirements:** {From PRD}

**Metrics to Track:**
{For web-app/fullstack:}
- Time to Interactive (TTI): Target < {X}ms
- First Contentful Paint (FCP): Target < {X}ms
- Bundle size: Target < {X}KB

{For api:}
- API response times: Target < {X}ms
- Throughput: Target {X} requests/second

{For cli:}
- Startup time: Target < {X}ms
- Command execution time: Target < {X}ms

**Tools:**
- {Appropriate tools based on project type}

### Security Testing

**Requirements:** {From PRD}

**Automated Checks:**
- Dependency vulnerability scanning
- Static analysis for security issues
- {Other based on PRD security requirements}

**Manual Review Areas:**
- Authentication flows
- Authorization boundaries
- Data validation
- Sensitive data handling

## Test Data Management

### Approach
- **Unit/Integration:** Factories and fixtures
- **E2E:** Seeded test database or mocked APIs

### Test User Accounts
{Define test users for different roles from PRD user types}

| Role | Username | Purpose |
|------|----------|---------|
| {Role from PRD} | test-{role}@example.com | Testing {role}-specific features |

## CI/CD Integration

### Commands Reference
From `.claude/project.yaml`:
- **Lint:** `{build.commands.lint}`
- **Type Check:** `{build.commands.typecheck}`
- **Build:** `{build.commands.build}`
- **Test:** `{build.commands.test}`
- **Dev Server:** `{build.commands.dev}`

### Pipeline Stages

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│    Lint     │ → │    Unit     │ → │ Integration │ → │     E2E     │
│  & Types    │   │   Tests     │   │    Tests    │   │   Tests     │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
```

### When Tests Run
- **On every PR:** Lint, Types, Unit, Integration
- **On merge to main:** All tests + E2E
- **Nightly:** Full E2E suite, Visual regression, Performance

### Failure Handling
- PRs blocked if any tests fail
- Flaky test policy: {How to handle}

## Manual Testing Checklist

For each milestone/release, manually verify:

### Functional Testing
- [ ] All acceptance criteria from PRD met
- [ ] Edge cases handled gracefully
- [ ] Error states display correctly

{Include if project has UI:}
### Cross-Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile browsers (if applicable)

### Device Testing
- [ ] Desktop (1920x1080, 1440x900)
- [ ] Tablet (768px width)
- [ ] Mobile (375px width)

### Accessibility Manual Testing
- [ ] Full keyboard navigation test
- [ ] Screen reader test (VoiceOver/NVDA)
- [ ] High contrast mode
- [ ] Reduced motion preference respected

## Test Documentation

### Test Case Format
Each E2E test should document:
- **Preconditions:** What must be true before the test
- **Steps:** Numbered steps to execute
- **Expected Result:** What success looks like
- **Linked Requirement:** Reference to PRD feature/acceptance criteria

### Bug Report Format
- **Summary:** One-line description
- **Steps to Reproduce:** Numbered steps
- **Expected Behavior:** What should happen
- **Actual Behavior:** What actually happens
- **Environment:** Browser, device, etc.
- **Screenshots/Video:** If applicable

## Document History
- **Created:** {Date}
- **Last Updated:** {Date}
- **Derived From:** PRD v{X}, Brand Guide v{X}
```

## Present Summary

**For technical users:**

---

**Testing Strategy Generated!**

Based on your PRD and Brand Guide, here's the testing approach:

- **Unit Tests:** {Framework} targeting {X%} coverage
- **Integration Tests:** {Framework}
- **E2E Tests:** {Tool} covering {N} critical user flows
- **Visual Testing:** {Tool}
- **Accessibility:** {Standard} with {Tool}

Commands configured from `.claude/project.yaml`:
- Test: `{build.commands.test}`
- Lint: `{build.commands.lint}`

The full document is saved at `docs/TESTING_STRATEGY.md`

**Next step:** Create your Lakar project structure with `/fra:lakar`

---

**For non-technical users:**

---

**Testing Plan Created!**

Here's how we'll make sure **{Product Name}** works correctly:

- **Automatic code checks** - Catches bugs as code is written
- **User flow testing** - Simulates real users to test main features
- **Visual checks** - Makes sure everything looks right
- **Accessibility testing** - Ensures it works for everyone

This is all automatic - bugs will be caught before they reach users.

The full plan is saved at `docs/TESTING_STRATEGY.md`

**Next step:** Type `/fra:lakar` to create your task list in Lakar.

---

## Important

- This command should be mostly automated, requiring minimal user input
- The testing strategy should directly trace back to PRD features and Brand Guide requirements
- Use the build.tool and build.commands from project.yaml - don't assume Nx or any specific tool
- Adjust sections based on project.type - don't include UI testing sections for CLIs/APIs
- The strategy should be practical and implementable, not overly ambitious
- Adapt language complexity based on user.mode
