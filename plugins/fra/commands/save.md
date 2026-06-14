---
description: Save your work by committing and pushing changes to GitHub
allowed-tools: AskUserQuestion, Bash, Read
---

This command is an alias for `/zao:save`. Running the save workflow.

## Steps

1. **Read project configuration**
   - Load `.claude/project.yaml` to get `user.mode` for appropriate messaging

2. **Execute /zao:save workflow**

   Follow the exact same steps as `/zao:save`:

### Step 1: Check for Changes

```bash
git status --porcelain
```

If no changes:

**For technical users:**
> "Everything is already saved! No uncommitted changes."

**For non-technical users:**
> "Everything is already saved! There are no new changes to commit."

- Stop execution

### Step 2: Show What Will Be Saved

```bash
git status --short
```

**For technical users:**
> "Changes to commit:"
> {List files with their git status}

**For non-technical users:**
> "Here's what will be saved:"
> - {List files in plain language, e.g., "Updated the product requirements", "Added new design guidelines"}

### Step 3: Generate a Commit Message

Generate a commit message based on the changes.

- Use conventional commit format based on `commits.types` from config
- Add the footer from `commits.footer`

### Step 4: Commit Changes

```bash
git add -A
git commit -m "{generated message}

{commits.footer from config}"
```

### Step 5: Push to GitHub

```bash
git push origin $(git branch --show-current)
```

If push fails due to remote changes:

**For technical users:**
> "Remote has diverged. Rebasing and retrying..."

**For non-technical users:**
> "Someone else has made changes. Let me sync those first..."

```bash
git pull --rebase origin $(git branch --show-current)
git push origin $(git branch --show-current)
```

If there are conflicts:

**For technical users:**
> "Merge conflicts detected. Files with conflicts: {list}. Resolve conflicts and run `/fra:save` again."

**For non-technical users:**
> "There are some conflicting changes that need to be resolved. This happens when the same files were changed in different ways. You may need help from a developer to sort this out."

### Step 6: Confirm Save

**For technical users:**

---

**Committed and pushed.**

- **Branch:** {branch}
- **Commit:** {short hash} - {message}
- **Files:** {count} changed

---

**For non-technical users:**

---

**Saved!**

Your changes have been saved to GitHub.

**What was saved:**
- {Summary of changes in plain language}

---

## Important

- This is an alias for `/zao:save` - same functionality, different name for discoverability
- Adjust messaging based on `user.mode` from project config
- Always show what's being saved before committing
- Handle push failures gracefully with clear explanations
