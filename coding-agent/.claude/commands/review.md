---
description: Review code changes (branch, unstaged, staged, or file)
argument-hint: [branch|unstaged|staged|file:path]
allowed-tools: Read, Grep, Glob, Bash
---

Review code changes based on the argument:

**Determine what to review:**
- If `$1` is "branch" or empty: `git diff main...HEAD`
- If `$1` is "unstaged": `git diff`
- If `$1` is "staged": `git diff --cached`
- If `$1` is "last" or "commit": `git show HEAD`
- If `$1` starts with "file:": Review the specific file path after the colon
- Otherwise treat `$1` as a branch name: `git diff $1...HEAD`

**Review Process:**

1. Get the diff using the appropriate git command
2. For each changed file, analyze:
   - Security vulnerabilities (OWASP top 10)
   - Code quality (complexity, duplication, clarity)
   - Performance issues (N+1 queries, inefficient algorithms)
   - Error handling completeness
   - Backend best practices

3. Provide structured feedback:

```markdown
## Review: [scope]

### Summary
Brief overview of changes and overall assessment.

### Critical Issues (Must Fix)
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|

### Major Issues (Should Fix)
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|

### Minor Issues (Consider)
Suggestions and improvements.

### Security Checklist
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Queries parameterized
- [ ] Auth checks in place

### Positive Observations
What was done well.

### Verdict
APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION
```
