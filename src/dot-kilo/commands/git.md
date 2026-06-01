---
description: Git operations with security scan and auto-commit (Git Manager Agent)
---

# 📦 GIT MANAGER AGENT

Git operation:

**Request:** {{args}}

## QUICK COMMANDS

| Command | Action | Time |
|---------|--------|------|
| `/git cm` | Commit with auto-message | 10-15s |
| `/git cp` | Commit + Push | 15-20s |
| `/git merge` | Merge branches | 10-20s |
| `/git status` | Review changes | 5s |
| `/git pr` | Generate PR summary | 30s |

---

## AUTO-COMMIT MESSAGE

### From Diff Analysis
```bash
git diff --staged
```

### Message Format (Conventional Commits)
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Commit Types
| Type | Use Case |
|------|----------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code restructuring |
| `perf` | Performance improvement |
| `test` | Adding tests |
| `chore` | Maintenance (deps, config) |
| `style` | Formatting (no code change) |

---

## SECURITY SCAN (Pre-commit)

### ❌ Patterns Blocked
```javascript
// API Keys
const API_KEY = "sk-1234567890abcdef";

// Database URLs
const DB_URL = "postgres://user:pass@host/db";

// OAuth Tokens
const TOKEN = "ghp_xxxxxxxxxxxx";

// AWS Credentials
const AWS_SECRET = "wJalrXUtnFEMI/K7MDENG/bPxRf";
```

### ✅ Allowed Patterns
```javascript
const API_KEY = process.env.API_KEY;
const DB_URL = process.env.DATABASE_URL;
```

### Scan Result
| Check | Status | Details |
|-------|--------|---------|
| API Keys | ✅/❌ | `file.ts:42` |
| DB Credentials | ✅/❌ | - |
| OAuth Tokens | ✅/❌ | - |
| Private Keys | ✅/❌ | - |

**Block commit if secrets detected!**

---

## MULTI-FILE DETECTION

For complex changes across multiple files:
```
feat(dashboard): add interactive chart component

- Add Chart.tsx with D3 integration
- Update Dashboard.tsx to include chart
- Add chart styles in styles.css
- Update tests for new component
```

---

## WORKFLOW

### Standard Commit
```bash
git status           # 1. Review changes
git add .            # 2. Stage files
/git cm              # 3. Auto-commit
git log -1           # 4. Verify
/git cp              # 5. Push (optional)
```

### Fix Push Failures
```bash
git pull --rebase origin main
# Resolve conflicts if any
/git cp              # Retry push
```

---

## PRE-PUSH SAFETY CHECKS (for /git cp)

### 1. Pre-Push Validation
Before pushing, automatically run:
```
Running pre-push checks...
✓ TypeScript: No errors
✓ Lint: Passed
✓ Tests: All passed (if fast)
✓ Security: No sensitive files
Safe to push.
```

### 2. Conflict Detection
```
⚠ Warning: Remote has changes
Remote branch has X new commits.
Options:
1. Pull and rebase: git pull --rebase
2. Pull and merge: git pull
3. Cancel push
```

### 3. Force Push Prevention
```
❌ Error: Would require force push
Your branch is behind 'origin/main' by X commits.
Options:
1. Pull and rebase: git pull --rebase
2. Create new branch
3. Cancel
```

**Never force push to main/master without explicit approval!**

### Logical Grouping
```bash
git add src/auth/*
/git cm              # Commits only auth

git add src/components/*
/git cm              # Separate UI changes
```

### Merge Branches
```bash
/git merge feature-branch into main

# Workflow:
# 1. Checkout target branch
# 2. Merge source branch
# 3. Resolve conflicts if any
# 4. Commit merge
# 5. Push if requested
```

---

## PR FORMAT (for /git pr)

### Auto-generated PR Description:
```markdown
## Summary
[Brief description of changes]

## Changes Made
- ✅ Feature: [description]
- 🐛 Fix: [description]
- ♻️ Refactor: [description]

## Files Changed
- `src/file1.ts` - [description]
- `src/file2.ts` - [description]

## Test Plan
- [ ] Unit tests pass
- [ ] Manual testing on localhost
- [ ] No TypeScript errors
- [ ] No lint warnings

## Screenshots (if UI changes)
[Attach screenshots]

## Checklist
- [ ] Code follows project conventions
- [ ] Documentation updated
- [ ] No breaking changes
```

### Usage:
```bash
/git pr                     # PR to main
/git pr develop            # PR to develop
/git pr --draft            # Draft PR
```

---

## SAFETY RULES
- ✅ Always review before commit
- ✅ Conventional commits format
- ❌ No force push to main/master
- ✅ Security scan before push
- ✅ Backup before risky ops

> **Key Takeaway:** Clean commit history with security-first automation. No leaked secrets, no AI attribution.

