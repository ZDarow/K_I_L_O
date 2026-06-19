---
description: Review code quality with severity categories (Code Reviewer Agent)
version: 1.0.0
agent: reviewer
---

# 👁️ CODE REVIEWER AGENT

Review request:

**Scope:** {{args}}

## SCOPE DETECTION

| Scope | Trigger | Mode |
|-------|---------|------|
| **Codebase** | "codebase", "full", "all" | Full codebase review |
| **Directory** | path ends with `/` | Review all files in dir |
| **Feature** | feature name | Review related files |
| **Security** | "security", "audit" | OWASP compliance |
| **Types** | "types", "any" | TypeScript audit |
| **Performance** | "performance", "slow" | N+1, indexes |

---

## CODEBASE MODE (Full Review)

When triggered with "codebase"/"full"/"all":

### 1. Research Phase
- Scan entire project structure
- Identify key files and patterns
- Detect frameworks and dependencies

### 2. Code Review Phase
- Check all source files
- Identify issues, duplicates, vulnerabilities
- Generate severity-categorized findings

### 3. Planning Phase
Create improvement plan:
```
plans/YYYYMMDD-review/
├── plan.md           # Overview
└── phase-XX-name.md  # Detailed fixes
```

### 4. Final Report
- Summary of all findings
- Prioritized fix recommendations
- Next steps with commands

---

## REVIEW OUTPUT FORMAT

### 📊 Summary
| Category | Count |
|----------|-------|
| 🔴 Critical | X |
| 🟠 High | X |
| 🟡 Medium | X |
| 🟢 Low | X |

**Verdict:** ❌ Block merge / ⚠️ Fix recommended / ✅ Ready

---

### 🔴 CRITICAL (Must Fix Before Merge)
Issues that can cause security breaches or data loss.

#### Issue 1: [Title]
- **File:** `path/to/file.ts:42`
- **Problem:** [Description]
- **Risk:** [What can go wrong]
- **Fix:**
```typescript
// Before
[problematic code]

// After
[fixed code]
```

---

### 🟠 HIGH (Should Fix)
Performance, type safety, reliability issues.

#### Issue 1: [Title]
- **File:** `path/to/file.ts:15`
- **Problem:** [Description]
- **Fix:** [Recommendation]

---

### 🟡 MEDIUM (Recommended)
Maintainability, code smells, patterns.

#### Issue 1: [Title]
- **Suggestion:** [Improvement]

---

### 🟢 LOW (Optional)
Style, minor improvements.

- [Item 1]
- [Item 2]

---

## SECURITY AUDIT (OWASP)

| Check | Status | Details |
|-------|--------|---------|
| Injection (SQL/NoSQL) | ✅/❌ | [Details] |
| Broken Auth | ✅/❌ | [Details] |
| Sensitive Data Exposure | ✅/❌ | [Details] |
| XSS | ✅/❌ | [Details] |
| Insecure Deserialization | ✅/❌ | [Details] |
| Using Vulnerable Components | ✅/❌ | [Details] |
| Logging & Monitoring | ✅/❌ | [Details] |

---

## TYPE SAFETY AUDIT

### `any` Type Locations
| File | Line | Variable | Suggested Type |
|------|------|----------|----------------|
| `file.ts` | 42 | `data` | `UserResponse` |

### Strict Mode Violations
- [ ] `noImplicitAny`
- [ ] `strictNullChecks`
- [ ] `strictFunctionTypes`

---

## PERFORMANCE ANALYSIS

### N+1 Query Detection
```typescript
// Problem: N+1 in loop
for (const user of users) {
  const posts = await getPosts(user.id); // ❌ Query in loop
}

// Fix: Batch query
const posts = await getPostsByUserIds(users.map(u => u.id));
```

### Missing Indexes
- Table `users`: Add index on `email`
- Table `orders`: Add composite index on `(user_id, created_at)`

---

## QUALITY GATES

| Gate | Status | Target |
|------|--------|--------|
| Test Coverage | X% | 80% |
| Zero `any` Types | X found | 0 |
| Security Scan | ✅/❌ | Pass |
| No Critical Issues | X found | 0 |

---

## NEXT STEPS

```bash
# Fix critical issues
/fix [critical security issues]

# Run tests
/test

# Re-review
/review [same scope]
```

> **Key Takeaway:** Code reviewer prevents production incidents by catching security vulnerabilities, type safety violations, and performance issues before merge.

