---
name: implement
description: Implements a feature using BDD/TDD — one test at a time
---

Implement $ARGUMENTS using strict TDD:

## Process
1. Read the feature description / acceptance criteria
2. List all acceptance criteria as a numbered checklist
3. For EACH criterion, one at a time:
   a. Write ONE failing RSpec test
   b. Run `docker compose exec -T web bundle exec rspec` — confirm it fails (RED)
   c. Write the minimum code to make it pass
   d. Run `docker compose exec -T web bundle exec rspec` — confirm it passes (GREEN)
   e. Ask: "Criterion N done — move to next?" Wait for approval.
4. After all criteria pass: run full suite `docker compose exec -T web bundle exec rspec`

## Rules
- Never write more than one test at a time
- Never skip the red-green cycle
- Use FactoryBot for test data (see spec/factories/)
- Use service objects for business logic (app/services/)
- Show test output after each run
- If a test fails unexpectedly, fix it before moving on
