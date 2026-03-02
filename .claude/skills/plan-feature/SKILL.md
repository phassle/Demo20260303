---
name: plan-feature
description: Creates a multi-phase implementation plan for a feature
allowed-tools: Read, Grep, Glob
---

Create an implementation plan for: $ARGUMENTS

## Process
1. Analyze the feature request
2. Read relevant existing code (models, controllers, services, specs)
3. Identify affected files and new files needed
4. Create a phased plan

## Plan Format

### Understanding
- Summarize the feature in 1-2 sentences
- List assumptions

### Questions
- List any clarifying questions before proceeding

### Phase 1: Database
- Migrations needed
- Model changes (validations, associations, scopes)

### Phase 2: Business Logic
- Service objects to create/modify
- Where logic lives and why

### Phase 3: API
- Controller actions needed
- Pundit policies
- Routes

### Phase 4: Tests
- Model specs
- Service specs
- Request specs
- Key edge cases

### Phase 5: Verification
- Full test suite pass
- Rubocop clean
- Manual verification steps

### Files to Create/Modify
List every file with a one-line description of changes.

### Risks
- Potential issues or unknowns
