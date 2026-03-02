---
name: verify
description: Runs tests, reviews own code, and checks edge cases
---

Verify the current changes:

## Step 1: Run Tests
```bash
docker compose exec -T web bundle exec rspec
```
Report: total examples, failures, pending.

## Step 2: Run Linter
```bash
docker compose exec -T web bundle exec rubocop
```
Report: offenses found, auto-correctable count.

## Step 3: Self-Review
Review all uncommitted changes (git diff) for:
- N+1 queries (missing .includes/.preload)
- Business logic in controllers (should be in services)
- Missing Pundit authorization
- Missing validations
- Missing test coverage
- Hardcoded values that should be constants/config

## Step 4: Edge Cases
For each new/modified feature, check:
- nil/empty inputs
- Boundary values
- Unauthorized access attempts
- Concurrent modification scenarios

## Output
Summary table:
| Check | Status | Notes |
|-------|--------|-------|
| Tests | pass/fail | X examples, Y failures |
| Rubocop | pass/fail | Z offenses |
| Self-review | good/warning/must-fix | findings |
| Edge cases | covered/missing | list |
