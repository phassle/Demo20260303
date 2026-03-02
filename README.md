# Planima Workshop Demo Project

A minimal Rails 7.1 property management app for workshop exercises.

## Intentional issues (for workshop exercises)

1. **Missing validation** — WorkOrder allows empty descriptions (bug fix exercise)
2. **N+1 query** — WorkOrdersController#index loads associations one by one
3. **No Pundit authorization** — create endpoint has no access control
4. **No service objects** — business logic lives in controller
5. **No escalation logic** — old unassigned work orders stay at normal priority (BDD exercise)

## Tech stack
- Ruby on Rails 7.1
- PostgreSQL
- RSpec + FactoryBot
- Pundit (installed but not used yet)

## Commands
- `bundle exec rspec` — run tests
- `bin/rails server` — start dev server
- `bin/rails console` — Rails console
