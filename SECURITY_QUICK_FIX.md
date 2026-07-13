# Security Fixes - Quick Reference

## Critical Fixes Required (in order)

### 1. Add Authentication (JWT)

**File**: `Gemfile`
```ruby
gem 'jwt'
```

**File**: `app/controllers/api/v1/auth_controller.rb` (NEW)
```ruby
module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user, only: [:login]

      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          token = encode_token(user.id)
          render json: { token: token }, status: :ok
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      private

      def encode_token(user_id)
        JWT.encode({ user_id: user_id }, Rails.application.secrets.secret_key_base)
      end
    end
  end
end
```

**File**: `app/controllers/application_controller.rb` (UPDATE)
```ruby
class ApplicationController < ActionController::API
  before_action :authenticate_user
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index

  rescue_from StandardError, with: :handle_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from Pundit::NotAuthorizedError, with: :handle_authorization_error
  rescue_from JWT::DecodeError, with: :handle_decode_error
  rescue_from JWT::ExpiredSignature, with: :handle_expired_token

  private

  def authenticate_user
    token = request.headers['Authorization']&.split(' ')&.last
    if token
      payload = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
      @current_user = User.find_by(id: payload['user_id'])
    end
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def handle_authorization_error(exception)
    render json: { error: 'Not authorized' }, status: :forbidden
  end

  def handle_decode_error
    render json: { error: 'Invalid token' }, status: :unauthorized
  end

  def handle_expired_token
    render json: { error: 'Token expired' }, status: :unauthorized
  end

  # ... keep existing handlers ...
end
```

### 2. Add Authorization (Pundit)

**File**: `app/models/user.rb` (UPDATE)
```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :assigned_work_orders, class_name: "WorkOrder", foreign_key: :assigned_to_id
  has_many :managed_properties, class_name: "Property", foreign_key: :manager_id

  validates :name, :email, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: %w[admin manager technician] }

  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  def technician?
    role == 'technician'
  end
end
```

**File**: `app/policies/application_policy.rb` (NEW)
```ruby
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError
    end

    private

    attr_reader :user, :scope
  end
end
```

**File**: `app/policies/work_order_policy.rb` (NEW)
```ruby
class WorkOrderPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager? || user.technician?
  end

  def create?
    user.admin? || user.manager? || user.technician?
  end

  def update?
    user.admin? || (user.manager? && record.property.manager_id == user.id)
  end

  def destroy?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.joins(:property).where(properties: { manager_id: user.id })
      end
    end
  end
end
```

**File**: `app/controllers/api/v1/work_orders_controller.rb` (UPDATE)
```ruby
module Api
  module V1
    class WorkOrdersController < ApplicationController
      def index
        @property = Property.find(params[:property_id])
        authorize @property

        work_orders = @property.work_orders
          .includes(:property, :tenant, :assigned_to)

        render json: work_orders.map { |wo|
          {
            id: wo.id,
            title: wo.title,
            status: wo.status,
            priority: wo.priority,
            property: wo.property.name,
            tenant: wo.tenant&.name,
            assigned_to: wo.assigned_to&.name
          }
        }
      end

      def create
        @property = Property.find(params[:property_id])
        authorize @property

        @work_order = @property.work_orders.build(safe_work_order_params)
        authorize @work_order

        if @work_order.save
          render json: @work_order, status: :created
        else
          render json: { errors: @work_order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def safe_work_order_params
        params.require(:work_order).permit(:title, :description, :priority)
      end
    end
  end
end
```

### 3. Remove Hardcoded Credentials

**File**: `.gitignore` (UPDATE)
```
.DS_Store
*.log
tmp/
.env
.env.local
.env.*.local
config/master.key
```

**File**: `docker-compose.yml` (UPDATE)
```yaml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER:-workshop}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-change_me}
      POSTGRES_DB: ${DB_NAME:-workshop_development}
    # ... rest stays same ...

  web:
    # ...
    environment:
      DATABASE_URL: postgres://${DB_USER:-workshop}:${DB_PASSWORD:-change_me}@db:5432/${DB_NAME:-workshop_development}
      DATABASE_URL_TEST: postgres://${DB_USER:-workshop}:${DB_PASSWORD:-change_me}@db:5432/${DB_NAME}_test
      RAILS_ENV: development
```

**File**: `.env.example` (NEW - safe to commit)
```
DB_USER=workshop
DB_PASSWORD=change_me_in_production
DB_NAME=workshop_development
SECRET_KEY_BASE=your_secret_key_here
```

### 4. Fix N+1 Query

**File**: `app/controllers/api/v1/work_orders_controller.rb` (UPDATE)
```ruby
def index
  @property = Property.find(params[:property_id])

  work_orders = @property.work_orders
    .includes(:property, :tenant, :assigned_to)  # ADD THIS

  render json: work_orders.map { |wo|
    # ... rest stays same ...
  }
end
```

### 5. Fix Database Scope

**File**: `app/models/work_order.rb` (UPDATE)
```ruby
scope :by_priority, -> {
  order("ARRAY_POSITION(ARRAY['urgent', 'high', 'normal', 'low']::text[], priority)")
}
```

### 6. Add Production Environment Config

**File**: `config/environments/production.rb` (NEW/UPDATE)
```ruby
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false

  config.force_ssl = true
  config.ssl_options = {
    hsts: {
      max_age: 1.year.to_i,
      preload: true,
      includeSubdomains: true
    }
  }

  config.hosts = ENV.fetch('APP_HOSTS', 'localhost').split(',')

  config.action_dispatch.default_headers = {
    'X-Frame-Options' => 'SAMEORIGIN',
    'X-Content-Type-Options' => 'nosniff',
    'X-XSS-Protection' => '1; mode=block',
    'Referrer-Policy' => 'strict-origin-when-cross-origin'
  }
end
```

### 7. Update Development/Test Environments

**File**: `config/environments/development.rb` (UPDATE)
```ruby
Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true

  # Change this - don't clear hosts
  config.hosts = ['localhost', 'localhost:3000', '127.0.0.1']
end
```

**File**: `config/environments/test.rb` (UPDATE)
```ruby
Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = true

  # Change this - don't clear hosts
  config.hosts = ['localhost', '127.0.0.1']
end
```

## Database Migration

**File**: `db/migrate/[timestamp]_add_password_and_manager_to_users.rb` (NEW)
```ruby
class AddPasswordAndManagerToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :password_digest, :string
    add_reference :properties, :manager, foreign_key: { to_table: :users }
  end
end
```

## Testing (Minimum)

**File**: `spec/requests/api/v1/auth_spec.rb` (NEW)
```ruby
RSpec.describe 'Authentication', type: :request do
  describe 'POST /api/v1/auth/login' do
    let(:user) { create(:user, password: 'password') }

    it 'returns token with valid credentials' do
      post '/api/v1/auth/login',
           params: { email: user.email, password: 'password' }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['token']).to be_present
    end

    it 'returns 401 with invalid credentials' do
      post '/api/v1/auth/login',
           params: { email: user.email, password: 'wrong' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'Authorization' do
    it 'returns 401 without token' do
      get '/api/v1/properties/1/work_orders'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

## Quick Test

```bash
# 1. Start the app
docker-compose up

# 2. Create a user
rails c
user = User.create!(name: "Admin", email: "admin@example.com", password: "password", role: "admin")

# 3. Get token
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'

# 4. Use token
curl http://localhost:3000/api/v1/properties/1/work_orders \
  -H "Authorization: Bearer <token_from_step_3>"
```

## TODO Checklist

- [ ] Add `jwt` gem and bundle
- [ ] Create authentication controller
- [ ] Update application controller with auth/auth logic
- [ ] Add `password_digest` to User model
- [ ] Create Pundit policies
- [ ] Update work orders controller
- [ ] Create auth migration
- [ ] Update `.gitignore`
- [ ] Create `.env.example`
- [ ] Update docker-compose.yml
- [ ] Remove hardcoded creds from database.yml
- [ ] Fix N+1 query with `.includes()`
- [ ] Update database scope
- [ ] Create/update production.rb
- [ ] Create/update test.rb and development.rb
- [ ] Add authentication tests
- [ ] Add authorization tests
- [ ] Test with curl/Postman
- [ ] Run full test suite
- [ ] Remove old commits with credentials (git filter-branch)

## Files to Check

After implementing, verify these files are correct:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/application_controller.rb`
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/api/v1/work_orders_controller.rb`
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/Gemfile`
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/.gitignore`
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/docker-compose.yml`
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/config/environments/production.rb`
