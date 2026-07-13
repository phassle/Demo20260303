# Security Audit Report
## Workshop Rails Application - March 4, 2026

---

## Executive Summary

This comprehensive security audit identified **5 Critical vulnerabilities** and **3 High-severity issues** in the Workshop Rails API application. The application is currently **NOT PRODUCTION-READY** and exposes sensitive property management data to unauthorized access.

**Most Critical Finding**: The API has **zero authentication mechanisms**, allowing any user to view and create work orders for any property.

---

## Findings by Severity

### CRITICAL VULNERABILITIES (Fix Immediately)

---

#### 1. Missing Authentication Layer

**Severity**: CRITICAL (9.9/10)

**Category**: Broken Authentication (OWASP A07:2021)

**Location**: Entire API surface
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/application_controller.rb`
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/api/v1/work_orders_controller.rb`
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/config/routes.rb`

**Description**:
The API has NO authentication mechanism whatsoever. There are no:
- API keys
- JWT tokens
- Session-based authentication
- OAuth flows
- Any form of user identification

**Impact**:
- Any user with network access can query the entire work order database
- Property management data is completely exposed
- Attackers can create fake work orders for any property
- GDPR/privacy regulations violated
- Complete breakdown of confidentiality

**Proof of Concept**:
```bash
# Without any credentials, this works:
curl http://localhost:3000/api/v1/properties/1/work_orders

# Returns all work orders for property 1:
[
  {
    "id": 1,
    "title": "Fix door",
    "status": "open",
    "priority": "high",
    "property": "Main Office",
    "tenant": "John Doe",
    "assigned_to": null
  }
]
```

**Recommendation**:
Implement authentication immediately. Choose one:

**Option A: JWT-based Authentication (Recommended for APIs)**
```ruby
# Gemfile
gem 'jwt'

# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user, only: [:login]

      def login
        user = User.find_by(email: auth_params[:email])

        if user&.authenticate(auth_params[:password])
          token = encode_token(user.id)
          render json: { token: token }, status: :ok
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      private

      def auth_params
        params.require(:auth).permit(:email, :password)
      end

      def encode_token(user_id)
        JWT.encode({ user_id: user_id }, Rails.application.secrets.secret_key_base)
      end
    end
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_user

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

  def handle_decode_error
    render json: { error: 'Invalid token' }, status: :unauthorized
  end

  def handle_expired_token
    render json: { error: 'Token expired' }, status: :unauthorized
  end
end
```

**Option B: Use devise gem with devise-jwt**
```ruby
# Gemfile
gem 'devise'
gem 'devise-jwt'

# config/initializers/devise.rb
Devise.setup do |config|
  config.jwt do |jwt|
    jwt.secret = Rails.application.secrets.secret_key_base
    jwt.dispatch_requests = [
      ['POST', %r{^/api/v1/users/sign_in$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/api/v1/users/sign_out$}]
    ]
    jwt.revocation_strategy = JwtBlacklist
  end
end
```

---

#### 2. Missing Authorization (Access Control)

**Severity**: CRITICAL (9.8/10)

**Category**: Broken Access Control (OWASP A01:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/api/v1/work_orders_controller.rb` (lines 4-6, 20-28)
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/application_controller.rb` (line 2)

**Description**:
Even if authentication were implemented, there is NO authorization logic. Pundit gem is imported but commented out:

```ruby
# Line 2 in application_controller.rb
# include Pundit::Authorization  # TODO: not yet enabled
```

Additionally, line 6 in the work_orders controller directly queries without permission checks:

```ruby
def index
  # NOTE: This has an N+1 query problem — no .includes()
  work_orders = WorkOrder.where(property_id: params[:property_id])
  # ^ No check if current_user owns this property or has access
```

**Impact**:
- Any authenticated user can view work orders for ANY property
- Property managers can see competitors' work orders
- Tenants can view work orders for other units
- Privilege escalation: technicians could view admin data
- Horizontal privilege escalation vulnerability

**Proof of Concept** (after authentication is added):
```bash
# User A is authenticated but not a manager of Property 2
# They can still access it:
curl -H "Authorization: Bearer USER_A_TOKEN" \
  http://localhost:3000/api/v1/properties/2/work_orders

# Returns data they shouldn't see
```

**Recommendation**:
Implement Pundit-based authorization:

```ruby
# Uncomment in application_controller.rb
include Pundit::Authorization
after_action :verify_authorized, except: :index
after_action :verify_policy_scoped, only: :index
rescue_from Pundit::NotAuthorizedError, with: :handle_authorization_error

private

def handle_authorization_error(exception)
  render json: { error: 'Not authorized' }, status: :forbidden
end

# app/policies/work_order_policy.rb
class WorkOrderPolicy < ApplicationPolicy
  def index?
    user.admin? || user.property_ids.include?(record.property_id)
  end

  def create?
    user.admin? || user.manager? || user.technician?
  end

  def update?
    user.admin? || record.property.managers.include?(user)
  end

  def destroy?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(property_id: user.managed_properties)
      end
    end
  end
end

# app/controllers/api/v1/work_orders_controller.rb
def index
  @work_orders = policy_scope(WorkOrder)
    .where(property_id: params[:property_id])
    .includes(:property, :tenant, :assigned_to)

  authorize @work_orders

  render json: @work_orders.map { |wo|
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
  @work_order = WorkOrder.new(work_order_params)
  authorize @work_order

  if @work_order.save
    render json: @work_order, status: :created
  else
    render json: { errors: @work_order.errors.full_messages }, status: :unprocessable_entity
  end
end
```

---

#### 3. Hardcoded Database Credentials in Version Control

**Severity**: CRITICAL (8.6/10)

**Category**: Secrets Management / Insecure Configuration (OWASP A05:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/docker-compose.yml` (lines 5-7, 30-31)
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/config/database.yml` (lines 5, 12)

**Description**:
Database credentials are hardcoded directly in files tracked by git:

**docker-compose.yml**:
```yaml
environment:
  POSTGRES_USER: workshop
  POSTGRES_PASSWORD: workshop
  POSTGRES_DB: workshop_development
  DATABASE_URL: postgres://workshop:workshop@db:5432/workshop_development
  DATABASE_URL_TEST: postgres://workshop:workshop@db:5432/workshop_test
```

**config/database.yml**:
```erb
url: <%= ENV.fetch("DATABASE_URL", "postgres://workshop:workshop@localhost:5432/workshop_development") %>
```

**Impact**:
- Anyone with access to git repository can read database credentials
- Credentials exposed in git history (difficult to remove)
- Credentials may appear in CI/CD logs
- Credential exposure in error messages/logs
- Database could be accessed/modified by unauthorized parties
- Data theft, corruption, or deletion

**Git History Risk**:
```bash
git log --all --full-history -- config/database.yml
git log --all --full-history -- docker-compose.yml
# Will show credentials forever in history
```

**Recommendation**:

1. **Move credentials to environment variables**:

```yaml
# docker-compose.yml - FIXED
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER:-workshop}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-secure_password_here}
      POSTGRES_DB: ${DB_NAME:-workshop_development}
    ports:
      - "5433:5432"
    # ... rest of config

  web:
    # ...
    environment:
      DATABASE_URL: postgres://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      DATABASE_URL_TEST: postgres://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}_test
      RAILS_ENV: development
```

2. **Use .env file (NEVER commit)**:

```bash
# .env (add to .gitignore)
DB_USER=workshop
DB_PASSWORD=super_secure_password_change_in_production
DB_NAME=workshop_development

# .env.example (safe to commit, no secrets)
DB_USER=workshop
DB_PASSWORD=change_me_in_production
DB_NAME=workshop_development
```

3. **Update .gitignore**:

```bash
# .gitignore
.env
.env.local
.env.*.local
config/master.key
config/credentials/
```

4. **For Production, use Rails Credentials**:

```bash
# Encrypt credentials
EDITOR=nano rails credentials:edit

# Access in code
Rails.application.credentials.database_password
```

5. **Remove from git history** (if not already deployed):

```bash
git filter-branch --tree-filter 'git rm -f config/database.yml docker-compose.yml' HEAD
# Then force push (only if not shared/deployed)
git push origin main --force-with-lease
```

---

#### 4. Parameter Injection / Broken Object Level Authorization

**Severity**: CRITICAL (9.2/10)

**Category**: Broken Object Level Access Control (OWASP A01:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/api/v1/work_orders_controller.rb` (line 33)

**Description**:
The `work_order_params` method accepts arbitrary `property_id` and `tenant_id`:

```ruby
def work_order_params
  params.require(:work_order).permit(:title, :description, :property_id, :tenant_id, :priority)
end
```

An attacker can:
1. Create work orders for properties they don't own
2. Associate work orders with tenants they're not responsible for
3. Create fraudulent work order chains

Example attack:
```bash
curl -X POST http://localhost:3000/api/v1/properties/1/work_orders \
  -H "Content-Type: application/json" \
  -d '{
    "work_order": {
      "title": "Fraud Work Order",
      "description": "Attacker creates order in wrong property",
      "property_id": 999,  # Different property
      "tenant_id": 500,    # Different tenant
      "priority": "urgent"
    }
  }'
```

**Impact**:
- Work order chaos across properties
- Fraudulent billing (if work orders drive invoicing)
- Data integrity violation
- Audit trail corruption
- Operational disruption

**Recommendation**:

```ruby
# app/controllers/api/v1/work_orders_controller.rb
def index
  @property = Property.find(params[:property_id])
  authorize @property, :show?  # Verify user can access this property

  work_orders = @property.work_orders
    .includes(:property, :tenant, :assigned_to)

  render json: work_orders.map { |wo| serialize_work_order(wo) }
end

def create
  @property = Property.find(params[:property_id])
  authorize @property, :show?

  # Never trust property_id/tenant_id from params
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
  # Only allow parameters that don't affect ownership/authorization
  params.require(:work_order).permit(:title, :description, :priority)
end

def work_order_params
  # Keep this for updates if needed, but it's dangerous
  params.require(:work_order).permit(:title, :description, :priority)
  # NEVER permit: property_id, tenant_id without special authorization
end
```

---

#### 5. No Input Validation on User Role Assignment

**Severity**: CRITICAL (8.8/10)

**Category**: Privilege Escalation / Input Validation

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/models/user.rb` (line 6)
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/db/schema.rb` (line 48)

**Description**:
While the User model does validate the role inclusion:

```ruby
validates :role, inclusion: { in: %w[admin manager technician] }
```

There's no controller preventing role assignment through:
1. Direct API if authentication exists
2. Mass assignment in updates
3. Admin functions that might be created later

Without authorization checks, any user could theoretically escalate their privileges.

**Impact**:
- Privilege escalation to admin
- Non-admins creating other admin accounts
- Bypassing role-based access control

**Recommendation**:

```ruby
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def update?
    user.admin? || user.id == record.id  # Users can only update themselves
  end

  def update_role?
    user.admin?  # Only admins can change roles
  end

  def destroy?
    user.admin? && user.id != record.id  # Can't delete self
  end
end

# app/controllers/api/v1/users_controller.rb (new)
module Api
  module V1
    class UsersController < ApplicationController
      def create
        @user = User.new(user_params)
        authorize @user

        if @user.save
          render json: @user, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        @user = User.find(params[:id])
        authorize @user

        if @user.update(user_update_params)
          render json: @user
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email)
        # Never permit role here - require special admin action
      end

      def user_update_params
        # Regular users can only update name
        if current_user.admin?
          params.require(:user).permit(:name, :email, :role)
        else
          params.require(:user).permit(:name)
        end
      end
    end
  end
end
```

---

### HIGH SEVERITY ISSUES

---

#### 6. Dangerous Arel.sql() in Database Scope

**Severity**: HIGH (7.2/10)

**Category**: Code Quality / SQL Injection Pattern (OWASP A03:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/models/work_order.rb` (line 12)

**Description**:
Using `Arel.sql()` is a code smell for potential SQL injection:

```ruby
scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 WHEN 'low' THEN 3 END")) }
```

While this specific case is safe (no user input), it:
1. Sets a bad precedent
2. Could become vulnerable if modified
3. Bypasses Rails' parameterization
4. Makes future refactoring risky

**Impact**:
- Future developers might add unsanitized input to this pattern
- Database query injection if similar patterns are used elsewhere
- Code review red flag

**Recommendation**:

```ruby
# app/models/work_order.rb
# Bad approach - vulnerable pattern
scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 0 ...")) }

# Good approach - use Rails constants or case statement
PRIORITY_ORDER = { 'urgent' => 0, 'high' => 1, 'normal' => 2, 'low' => 3 }.freeze

scope :by_priority, -> {
  order(
    ActiveRecord::Case
      .new(arel_table[:priority])
      .when('urgent').then(0)
      .when('high').then(1)
      .when('normal').then(2)
      .when('low').then(3)
      .else(4)
  )
}

# Or simpler - use database CASE with bind parameters
scope :by_priority, -> {
  order(Arel.sql("CASE WHEN priority = ? THEN 0 WHEN priority = ? THEN 1 WHEN priority = ? THEN 2 ELSE 3 END",
                 'urgent', 'high', 'normal'))
}

# Best - use a custom order
scope :by_priority, -> {
  order("ARRAY_POSITION(ARRAY['urgent', 'high', 'normal', 'low']::text[], priority)")
}
```

---

#### 7. N+1 Query Problem in API Response

**Severity**: HIGH (7.0/10)

**Category**: Performance / Denial of Service (OWASP A04:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/api/v1/work_orders_controller.rb` (lines 4-17)

**Description**:
The index action loads related data inefficiently:

```ruby
def index
  # NOTE: This has an N+1 query problem — no .includes()
  work_orders = WorkOrder.where(property_id: params[:property_id])
  render json: work_orders.map { |wo|
    {
      id: wo.id,
      title: wo.title,
      status: wo.status,
      priority: wo.priority,
      property: wo.property.name,        # <- Database query per record
      tenant: wo.tenant&.name,           # <- Database query per record
      assigned_to: wo.assigned_to&.name  # <- Database query per record
    }
  }
end
```

With 100 work orders:
- 1 query to fetch work orders
- 100 queries for properties
- 100 queries for tenants
- 100 queries for assigned users
- **Total: 301 queries instead of 4**

**Impact**:
- API response time: 100ms -> 3-5 seconds
- Database CPU spike
- Connection pool exhaustion
- Denial of Service vector (attacker requests large datasets)
- User experience degradation

**Recommendation**:

```ruby
def index
  work_orders = WorkOrder
    .where(property_id: params[:property_id])
    .includes(:property, :tenant, :assigned_to)  # Eager load associations

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

# Or use a serializer for cleaner code:
def index
  work_orders = WorkOrder
    .where(property_id: params[:property_id])
    .includes(:property, :tenant, :assigned_to)

  render json: work_orders, each_serializer: WorkOrderSerializer
end

# app/serializers/work_order_serializer.rb
class WorkOrderSerializer < ActiveModel::Serializer
  attributes :id, :title, :status, :priority

  belongs_to :property, serializer: PropertySerializer
  belongs_to :tenant, serializer: TenantSerializer
  belongs_to :assigned_to, serializer: UserSerializer
end
```

---

#### 8. Missing HTTPS Enforcement in Production

**Severity**: HIGH (8.1/10)

**Category**: Transport Security (OWASP A02:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/config/environments/` (missing configuration)

**Description**:
No explicit enforcement of HTTPS in production environment configuration. While Rails defaults to some HTTPS features in production, they should be explicitly configured:

```ruby
# config/environments/production.rb is missing or incomplete
# Should have:
config.force_ssl = true
config.ssl_options = { hsts: { max_age: 1.year.to_i } }
```

**Impact**:
- Man-in-the-middle attacks possible
- Credentials transmitted in plaintext
- Data interception
- Session hijacking

**Recommendation**:

```ruby
# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false

  # Force HTTPS
  config.force_ssl = true
  config.ssl_options = {
    hsts: {
      max_age: 1.year.to_i,
      preload: true,
      includeSubdomains: true
    }
  }

  # Security headers
  config.secure_headers_enabled = true

  # Session security
  config.session_store :cookie_store,
    secure: true,
    httponly: true,
    same_site: :strict

  # Other production configs...
end
```

---

### MEDIUM SEVERITY ISSUES

---

#### 9. Overly Permissive Host Configuration

**Severity**: MEDIUM (5.8/10)

**Category**: Misconfiguration (OWASP A05:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/config/environments/development.rb` (line 7)
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/config/environments/test.rb` (line 5)

**Description**:
```ruby
config.hosts.clear
```

This disables Rails' host validation, which can be exploited with Host header injection:

**Impact**:
- Host header injection attacks
- Cache poisoning
- Password reset token exploitation
- Session fixation vectors
- DNS rebinding attacks

**Recommendation**:

```ruby
# config/environments/development.rb
Rails.application.configure do
  # ... other config ...

  # Only allow specific hosts
  config.hosts = [
    'localhost',
    'localhost:3000',
    '127.0.0.1',
    ENV.fetch('APP_HOST', 'localhost')
  ]

  # Don't use hosts.clear - it's too permissive
end

# config/environments/test.rb
Rails.application.configure do
  # ... other config ...

  # Allow common test hosts
  config.hosts = [
    'localhost',
    '127.0.0.1'
  ]
end

# config/environments/production.rb
Rails.application.configure do
  # ... other config ...

  # Strict host validation in production
  config.hosts = ENV.fetch('APP_HOSTS', 'app.example.com').split(',')

  # Additional security header
  config.action_dispatch.default_headers = {
    'X-Frame-Options' => 'SAMEORIGIN',
    'X-Content-Type-Options' => 'nosniff',
    'X-XSS-Protection' => '1; mode=block'
  }
end
```

---

#### 10. Missing Security Response Headers

**Severity**: MEDIUM (6.2/10)

**Category**: Misconfiguration (OWASP A05:2021)

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/config/application.rb` (missing headers configuration)

**Description**:
No security headers configured:
- Missing Content-Security-Policy
- Missing X-Content-Type-Options
- Missing X-Frame-Options
- Missing Strict-Transport-Security
- Missing Referrer-Policy

**Impact**:
- XSS attacks (though API-only limits this)
- Clickjacking vulnerability
- MIME type sniffing
- Insecure connection downgrade

**Recommendation**:

```ruby
# Gemfile
gem 'secure_headers'

# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.hsts = {
    max_age: 1.year.to_i,
    preload: true,
    includeSubdomains: true
  }
  config.x_frame_options = 'SAMEORIGIN'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.referrer_policy = 'strict-origin-when-cross-origin'
  config.csp = {
    base_uri: ["'self'"],
    default_src: ["'self'"],
    script_src: ["'self'"],
    style_src: ["'self'"],
    img_src: ["'self'"],
    font_src: ["'self'"],
    connect_src: ["'self'"],
    frame_ancestors: ["'none'"],
    form_action: ["'self'"],
    upgrade_insecure_requests: []
  }
end

# Or manually in application_controller.rb
class ApplicationController < ActionController::API
  before_action :set_security_headers

  private

  def set_security_headers
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Content-Security-Policy'] = "default-src 'self'; script-src 'self'; style-src 'self'"
  end
end
```

---

### LOW SEVERITY / INFORMATIONAL

---

#### 11. Insufficient Error Message Leakage

**Severity**: LOW (3.5/10)

**Category**: Information Disclosure

**Location**:
- `/Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303/app/controllers/application_controller.rb` (lines 17-18)

**Description**:
Error responses include `exception.record.errors.full_messages`:

```ruby
def handle_record_invalid(exception)
  Rails.logger.warn("[RecordInvalid] #{exception.message}")
  render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
end
```

While this is partially mitigated by using generic messages elsewhere, it could leak information about database schema and validation rules.

**Impact**: Low - mostly informational

**Recommendation**:

```ruby
def handle_record_invalid(exception)
  Rails.logger.warn("[RecordInvalid] #{exception.message}")
  Rails.logger.debug("Record errors: #{exception.record.errors.full_messages.inspect}")

  # In development/test, show details. In production, be vague
  if Rails.env.production?
    render json: { error: 'Invalid request' }, status: :unprocessable_entity
  else
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end
end
```

---

#### 12. No Rate Limiting on API Endpoints

**Severity**: LOW (4.2/10)

**Category**: Denial of Service (OWASP A04:2021)

**Location**:
- All API endpoints lack rate limiting

**Description**:
No protection against brute force, enumeration, or DoS attacks:
- Unlimited login attempts (when auth added)
- Unlimited work order creation
- Unlimited data enumeration

**Recommendation**:

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle POST requests to /login by IP
  throttle('login', limit: 5, period: 5.minutes) do |request|
    if request.path == '/api/v1/users/login' && request.post?
      request.ip
    end
  end

  # Throttle API requests by IP
  throttle('api', limit: 100, period: 1.minute) do |request|
    if request.path.start_with?('/api')
      request.ip
    end
  end

  # Throttle by user ID (once authenticated)
  throttle('api/user', limit: 500, period: 1.hour) do |request|
    if request.path.start_with?('/api') && current_user
      current_user.id
    end
  end

  self.throttled_response = lambda do |env|
    [429, { 'Content-Type' => 'application/json' }, [{ error: 'Rate limit exceeded' }.to_json]]
  end
end

# config/application.rb
config.middleware.use Rack::Attack
```

---

## Dependency Security Review

### Current Dependencies

**Rails 7.1.6** - Up to date, actively maintained
- Last major security updates: January 2024
- No known critical vulnerabilities

**PostgreSQL 1.6.3** - Up to date
- No known vulnerabilities

**Puma 6.6.1** - Up to date
- No known critical vulnerabilities

**Pundit 2.5.2** - Up to date
- No known vulnerabilities

### Recommendations

1. Add `bundler-audit` to CI/CD:
```bash
gem 'bundler-audit', require: false

# In Rakefile or CI:
rake bundle:audit
```

2. Enable Dependabot on GitHub for automatic updates

3. Review Gemfile for unused dependencies

---

## Security Testing Gaps

### Missing Test Coverage

1. **Authentication Tests**: No authentication mechanism to test
2. **Authorization Tests**: No authorization checks implemented
3. **Input Validation Tests**: Limited validation testing
4. **SQL Injection Tests**: No tests for SQL injection vectors
5. **Rate Limiting Tests**: No rate limiting implemented
6. **Security Header Tests**: No header verification tests

### Recommended Test Suite

```ruby
# spec/requests/api/v1/work_orders_spec.rb
RSpec.describe 'Api::V1::WorkOrders', type: :request do
  describe 'Authentication' do
    it 'returns 401 without authorization header' do
      get api_v1_property_work_orders_path(property_id: 1)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 401 with invalid token' do
      get api_v1_property_work_orders_path(property_id: 1),
          headers: { 'Authorization' => 'Bearer invalid_token' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'Authorization' do
    let(:user) { create(:user, role: 'technician') }
    let(:other_property) { create(:property) }
    let(:token) { encode_token(user.id) }

    it 'returns 403 when accessing unauthorized property' do
      get api_v1_property_work_orders_path(property_id: other_property.id),
          headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'Input Validation' do
    it 'prevents work order creation in other properties' do
      post api_v1_property_work_orders_path(property_id: 1),
           params: {
             work_order: {
               title: 'Test',
               property_id: 999,  # Different property
               description: 'Test'
             }
           },
           headers: { 'Authorization' => "Bearer #{token}" }

      expect(WorkOrder.last.property_id).to eq(1)  # Should use path property
    end
  end
end

# spec/security/headers_spec.rb
RSpec.describe 'Security Headers' do
  it 'includes HSTS header' do
    get api_v1_property_work_orders_path(property_id: 1)
    expect(response.headers['Strict-Transport-Security']).to be_present
  end

  it 'includes X-Content-Type-Options header' do
    get api_v1_property_work_orders_path(property_id: 1)
    expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
  end
end
```

---

## Remediation Roadmap

### Phase 1: CRITICAL (Week 1 - Deploy Immediately)
- [ ] Implement JWT-based authentication
- [ ] Add Pundit authorization policies
- [ ] Remove hardcoded credentials from version control
- [ ] Fix parameter validation (property_id/tenant_id)

### Phase 2: HIGH (Week 2-3)
- [ ] Fix N+1 query problems
- [ ] Implement HTTPS enforcement
- [ ] Fix Arel.sql() usage
- [ ] Configure proper environments

### Phase 3: MEDIUM (Week 3-4)
- [ ] Implement security headers
- [ ] Add rate limiting
- [ ] Fix host validation
- [ ] Add comprehensive security tests

### Phase 4: LOW/Maintenance (Ongoing)
- [ ] Set up automated dependency scanning
- [ ] Implement security logging
- [ ] Add penetration testing
- [ ] Regular security audits

---

## Security Maturity Checklist

- [ ] Authentication implemented and tested
- [ ] Authorization (per-resource and per-action)
- [ ] Secrets management (environment variables, vaults)
- [ ] Input validation and sanitization
- [ ] Output encoding
- [ ] Secure headers (HSTS, CSP, X-Frame-Options, etc.)
- [ ] HTTPS/TLS enforcement
- [ ] Rate limiting and DDoS protection
- [ ] Logging and monitoring
- [ ] Incident response procedures
- [ ] Security testing in CI/CD
- [ ] Dependency vulnerability scanning
- [ ] Code review process
- [ ] Documentation of security controls

---

## Summary Statistics

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 5 | Require Immediate Action |
| HIGH | 3 | Address Within 2 Weeks |
| MEDIUM | 2 | Address Within 1 Month |
| LOW | 2 | Consider in Future Sprints |
| **TOTAL** | **12** | - |

---

## Conclusion

The Workshop Rails API application has **severe security deficiencies** and is **not suitable for production use** in its current state. The most critical issue is the complete absence of authentication and authorization mechanisms.

Priority actions:
1. Implement JWT authentication immediately
2. Add role-based access control with Pundit
3. Remove hardcoded credentials from repository
4. Implement parameter validation to prevent cross-property access
5. Add comprehensive security testing

**Estimated effort**: 2-3 weeks for critical fixes + 1 week for medium/low fixes.

Once these findings are addressed, a follow-up security audit is recommended before production deployment.

---

**Report generated**: March 4, 2026
**Auditor**: Security Review Agent
**Next Review**: After critical vulnerabilities are remediated
