---
name: upgrade-check
description: Analyzes deprecations and compatibility before a framework upgrade
allowed-tools: Read, Grep, Glob
---

Analyze upgrade readiness for: $ARGUMENTS

## Process

### Step 1: Current Versions
- Read Gemfile and Gemfile.lock
- List current versions of target gem and all dependencies

### Step 2: Deprecation Scan
Search the codebase for:
- Deprecated method calls
- Deprecated configuration options
- Patterns that will break in the target version

### Step 3: Dependency Compatibility
- Check if all gems in Gemfile are compatible with the target version
- Identify gems that need version bumps
- Flag gems that may not support the target version yet

### Step 4: Test Coverage Assessment
- Check current test suite — all green before starting?
- Identify areas with low coverage that are risky to upgrade

### Step 5: Migration Plan
For each breaking change found:
1. File and line where the issue exists
2. What needs to change
3. Suggested replacement code
4. Risk level (low/medium/high)

## Output
| Issue | Location | Risk | Fix |
|-------|----------|------|-----|
| ... | file:line | low/med/high | description |

### Recommended upgrade order
1. Fix deprecations (while still on current version)
2. Update gem version
3. Run tests
4. Fix any new failures
