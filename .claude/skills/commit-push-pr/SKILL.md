---
name: commit-push-pr
description: Commits changes, pushes to remote, and creates a pull request
---

Commit, push, and create PR for current changes:

## Step 1: Pre-flight
- Run `docker compose exec -T web bundle exec rspec` — all tests must pass
- Run `docker compose exec -T web bundle exec rubocop` — no offenses
- If either fails, stop and report. Do NOT commit failing code.

## Step 2: Review Changes
- Run `git diff --stat` to see changed files
- Run `git diff` to review all changes
- Summarize what was changed and why

## Step 3: Commit
- Stage relevant files (never use `git add .` blindly)
- Write a clear commit message:
  - First line: imperative, under 72 chars
  - Blank line
  - Body: explain what and why, not how

## Step 4: Push
- Push to the current feature branch
- If no upstream set: `git push -u origin $(git branch --show-current)`

## Step 5: Create PR
- Use `gh pr create`
- Title: matches the commit message first line
- Body: summary of changes, test plan, link to related issue if any

## Output
- Commit SHA
- PR URL
- Summary of what was included
