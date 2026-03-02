# Workshop Demo — Property Management API

## About
Minimal Rails 7.1 API-only app for property management. PostgreSQL database.
RSpec + FactoryBot for testing. Pundit for authorization (installed, not yet enabled).
Runs in Docker (`docker compose`). No frontend.

## Commands
All commands run inside the Docker container:
- Tests: `docker compose exec web bundle exec rspec`
- Single test: `docker compose exec web bundle exec rspec spec/models/work_order_spec.rb`
- Lint: `docker compose exec web bundle exec rubocop`
- Lint + fix: `docker compose exec web bundle exec rubocop --autocorrect`
- Routes: `docker compose exec web bundle exec rake routes`
- Console: `docker compose exec web bundle exec rails console`
- DB migrate: `docker compose exec web bundle exec rake db:migrate`

## Rules
- Be extremely concise. Sacrifice grammar for concision.
- At the end of each plan, list unresolved questions (if any).
- Always use service objects for business logic (`app/services/`).
- Never put business logic in controllers — thin controllers only.
- Use Pundit policies for all authorization (`app/policies/`).
- Use FactoryBot for test data — never create records manually in specs.
- Run `docker compose exec web bundle exec rspec` before every commit.
- Run `docker compose exec web bundle exec rubocop` before every commit.

## Architecture
```
app/
├── controllers/
│   ├── application_controller.rb   ← API base (Pundit include pending)
│   └── api/v1/
│       └── work_orders_controller.rb
├── models/
│   ├── property.rb       ← has_many :tenants, :work_orders
│   ├── user.rb           ← roles: admin, manager, technician
│   ├── tenant.rb         ← belongs_to :property
│   └── work_order.rb     ← belongs_to :property, :tenant, :assigned_to
├── services/             ← Business logic (create as needed)
├── policies/             ← Pundit policies (create as needed)
spec/
├── models/               ← Model specs
├── requests/             ← API endpoint specs (create as needed)
├── services/             ← Service specs (create as needed)
└── factories/            ← FactoryBot factories (4 exist)
```

## Known Issues (intentional — for workshop exercises)
1. WorkOrder allows empty descriptions (missing validation)
2. WorkOrdersController#index has N+1 query (no `.includes()`)
3. Create endpoint has no Pundit authorization
4. Business logic in controller (no service objects yet)
5. No escalation logic for old unassigned work orders

## Key Data
- Statuses: open, in_progress, completed, cancelled
- Priorities: low, normal, high, urgent
- User roles: admin, manager, technician
- Factory traits: `:old` (20 days ago), `:unassigned`, `:urgent`, `:technician`, `:admin`
