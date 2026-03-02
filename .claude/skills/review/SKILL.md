---
name: review
description: Reviews Ruby on Rails code for common issues
allowed-tools: Read, Grep, Glob
---

Review $ARGUMENTS:

## Rails
1. N+1 queries? Missing `.includes()` or `.preload()`?
2. Business logic in controller? Should be in service object?
3. Missing Pundit authorization?
4. Raw SQL without parameterization?
5. Missing validations on model?

## Testing
6. RSpec specs exist for all new code?
7. FactoryBot used for test data (never manual record creation)?
8. Edge cases covered (nil, empty, boundary values)?

## Security
9. Strong parameters used in controllers?
10. No mass assignment vulnerabilities?
11. Authorization checked before every action?

## Conventions
12. Thin controllers — logic delegated to services?
13. Service objects in app/services/?
14. Pundit policies in app/policies/?

## Output
For each file reviewed, categorize findings:
- **good** — No issues found
- **warning** — Minor issues or suggestions
- **must-fix** — Critical issues that must be addressed before merge
