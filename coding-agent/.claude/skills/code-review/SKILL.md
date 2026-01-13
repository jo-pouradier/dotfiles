---
name: code-review
description: Knowledge base for thorough code reviews focusing on backend best practices
license: MIT
compatibility: opencode
metadata:
  audience: backend-engineers
  workflow: code-review
---

# Code Review Skill

Comprehensive knowledge for reviewing backend code with focus on security, performance, and maintainability.

## When to Use

- Reviewing pull requests
- Analyzing branch diffs
- Checking unstaged/staged changes
- Auditing specific files or modules
- Security assessments

## Git Commands Reference

```bash
# Compare current branch to main
git diff main...HEAD

# Show unstaged changes
git diff

# Show staged changes
git diff --cached

# Show specific commit
git show <commit-hash>

# Show changes in last N commits
git log -p -n 3

# Show files changed in branch
git diff --name-only main...HEAD

# Show stats (insertions/deletions)
git diff --stat main...HEAD
```

## Security Checklist

### Authentication & Authorization
- [ ] Authentication required for protected endpoints
- [ ] Authorization checks for resource access
- [ ] Session management is secure
- [ ] Password policies enforced
- [ ] MFA implementation (if applicable)

### Input Validation
- [ ] All user input validated
- [ ] Input length limits enforced
- [ ] Type checking implemented
- [ ] Whitelist validation where possible
- [ ] File upload restrictions

### Data Protection
- [ ] No hardcoded secrets or credentials
- [ ] Sensitive data encrypted at rest
- [ ] Sensitive data encrypted in transit
- [ ] PII handled according to regulations
- [ ] Proper data sanitization before storage

### SQL/Database
- [ ] Parameterized queries (no string concatenation)
- [ ] ORM used correctly (no raw queries with user input)
- [ ] Database permissions follow least privilege
- [ ] Sensitive fields not logged

### API Security
- [ ] Rate limiting implemented
- [ ] CORS configured correctly
- [ ] Error messages don't leak internal details
- [ ] API versioning strategy
- [ ] Request size limits

## Code Quality Patterns

### Anti-Patterns to Flag

**N+1 Queries:**
```python
# BAD
for user in users:
    orders = get_orders(user.id)  # Query per user

# GOOD
users_with_orders = get_users_with_orders()  # Single query with join
```

**Missing Error Handling:**
```python
# BAD
result = external_api.call()
return result.data

# GOOD
try:
    result = external_api.call()
    return result.data
except ApiError as e:
    logger.error(f"API call failed: {e}")
    raise ServiceUnavailableError()
```

**Hardcoded Values:**
```python
# BAD
timeout = 30
api_url = "https://api.example.com"

# GOOD
timeout = config.API_TIMEOUT
api_url = config.API_URL
```

**Missing Transactions:**
```python
# BAD
user = create_user(data)
wallet = create_wallet(user.id)
# If wallet creation fails, orphan user exists

# GOOD
with transaction():
    user = create_user(data)
    wallet = create_wallet(user.id)
```

## Performance Checklist

### Database
- [ ] Appropriate indexes exist for queries
- [ ] No SELECT * in production code
- [ ] Pagination implemented for list endpoints
- [ ] Connection pooling configured
- [ ] Query explain plans reviewed for complex queries

### Caching
- [ ] Cacheable data identified
- [ ] Cache invalidation strategy defined
- [ ] TTLs appropriate for data freshness needs
- [ ] Cache key collision prevention

### General
- [ ] No blocking operations in async contexts
- [ ] Resource cleanup (connections, file handles)
- [ ] Appropriate timeouts configured
- [ ] Batch operations where applicable

## Review Output Template

```markdown
## Review Summary

**Branch:** `feature/xyz`
**Files Changed:** 12
**Lines:** +450 / -120

### Overview
Brief summary of what the changes do.

### Critical Issues
| Severity | File | Line | Issue | Fix |
|----------|------|------|-------|-----|
| CRITICAL | auth.py | 45 | SQL injection | Use parameterized query |

### Security Assessment
- [x] No hardcoded secrets
- [x] Input validation present
- [ ] Missing rate limiting on /api/login

### Performance Notes
- N+1 query detected in user_service.py:78
- Consider adding index on orders.user_id

### Code Quality
- Good: Clear separation of concerns
- Improve: Add docstrings to public methods

### Testing
- Unit tests added: Yes
- Integration tests: Missing for payment flow

### Verdict
**REQUEST_CHANGES** - Address critical security issue before merge
```

## Severity Definitions

| Level | Description | Action |
|-------|-------------|--------|
| CRITICAL | Security vulnerability, data loss risk | Block merge |
| MAJOR | Bugs, significant issues | Should fix before merge |
| MINOR | Code quality, style issues | Nice to fix |
| INFO | Suggestions, alternatives | Optional |
