---
description: Save your work by committing and pushing changes to GitHub
allowed-tools: AskUserQuestion, Bash, Read
---

Save all current changes by committing and pushing to GitHub.

## Steps

### Step 1: Read Project Configuration

Load `.claude/project.yaml` to get:
- `user.mode` - technical or non-technical (affects messaging)
- `commits.footer` - footer to append to commits
- `commits.types` - commit type prefixes

### Step 2: Check for Changes

```bash
git status --porcelain
```

If no changes:

**For technical users:**
> "Nothing to commit. Working tree clean."

**For non-technical users:**
> "Everything is already saved! There are no new changes to commit."

- Stop execution

### Step 3: Show What Will Be Saved

```bash
git status --short
```

**For technical users:**
> "Staged for commit:"
> ```
> {git status output}
> ```

**For non-technical users:**
> "Here's what will be saved:"
> - {List files in plain language, e.g., "Updated the product requirements", "Added new design guidelines"}

### Step 4: Generate a Commit Message

Analyze the changes and generate an appropriate commit message:
- Use conventional commit format with types from `commits.types`
- For mixed changes, use `chore:` as the type
- Keep the first line under 72 characters

### Step 5: Commit Changes

```bash
git add -A
git commit -m "{type}: {description}

{commits.footer}"
```

### Step 6: Push to GitHub

```bash
git push origin $(git branch --show-current)
```

If push fails due to remote changes:

**For technical users:**
> "Remote diverged. Rebasing..."

**For non-technical users:**
> "Someone else has made changes. Let me sync those first..."

```bash
git pull --rebase origin $(git branch --show-current)
git push origin $(git branch --show-current)
```

If there are conflicts:

**For technical users:**
> "Rebase conflict in: {files}. Resolve and run `/zao:save` again."

**For non-technical users:**
> "There are some conflicting changes that need to be resolved. This happens when the same files were changed in different ways. You may need help from a developer to sort this out."

### Step 7: Confirm Save

**For technical users:**

---

**Pushed**

- **Branch:** `{branch}`
- **Commit:** `{short-hash}` {message}
- **Files:** {N} changed

---

**For non-technical users:**

---

**Saved!**

Your changes have been saved to GitHub.

**What was saved:**
- {Summary of changes in plain language}

---

## Important

- Always show what's being saved before committing
- Use commit types from `commits.types` in config
- Use `commits.footer` from config
- Adjust messaging based on `user.mode`
- Handle push failures gracefully with clear explanations
