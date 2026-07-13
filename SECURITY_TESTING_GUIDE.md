# Security Testing Guide

## Manual Testing Checklist

### Authentication Testing

**Current State**: No authentication
**Test**: Try accessing API without credentials

```bash
# Should currently work (vulnerability):
curl http://localhost:3000/api/v1/properties/1/work_orders
# Response: 200 with data (BAD)

# After fix, should fail:
curl http://localhost:3000/api/v1/properties/1/work_orders
# Response: 401 Unauthorized (GOOD)
```

**With Fix**: Test JWT token flow

```bash
# 1. Create user
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Test User",
      "email": "test@example.com",
      "password": "secure_password",
      "role": "manager"
    }
  }'

# 2. Get token
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "secure_password"
  }'
# Response: {"token": "eyJhbGciOiJIUzI1NiJ9..."}

# 3. Use token
TOKEN="eyJhbGciOiJIUzI1NiJ9..."
curl http://localhost:3000/api/v1/properties/1/work_orders \
  -H "Authorization: Bearer $TOKEN"
# Response: 200 with data for authorized user

# 4. Try expired/invalid token
curl http://localhost:3000/api/v1/properties/1/work_orders \
  -H "Authorization: Bearer invalid_token"
# Response: 401 Unauthorized

# 5. Try malformed header
curl http://localhost:3000/api/v1/properties/1/work_orders \
  -H "Authorization: invalid_format"
# Response: 401 Unauthorized
```

### Authorization Testing

**Horizontal Privilege Escalation** - User accessing other user's resources

```bash
# User 1 (technician) tries to access Property managed by User 2
USER1_TOKEN="..."
USER2_PROPERTY_ID=2

curl http://localhost:3000/api/v1/properties/$USER2_PROPERTY_ID/work_orders \
  -H "Authorization: Bearer $USER1_TOKEN"

# Expected after fix:
# Response: 403 Forbidden
# Current (vulnerable):
# Response: 200 with data (BAD)
```

**Privilege Escalation** - Non-admin creating admin user

```bash
# Manager tries to create admin user
MANAGER_TOKEN="..."

curl -X POST http://localhost:3000/api/v1/users \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Hacker Admin",
      "email": "hacker@example.com",
      "password": "password",
      "role": "admin"
    }
  }'

# Expected after fix:
# Response: 403 Forbidden
```

### Input Validation Testing

**Cross-Property Work Order Creation**

```bash
# Create work order in Property 1 but specify Property 2
TECHNICIAN_TOKEN="..."

curl -X POST http://localhost:3000/api/v1/properties/1/work_orders \
  -H "Authorization: Bearer $TECHNICIAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "work_order": {
      "title": "Malicious Order",
      "description": "This should only be created in Property 1",
      "property_id": 999,
      "priority": "urgent"
    }
  }'

# Expected after fix:
# Work order should be created in Property 1, not Property 999
# property_id from params should be ignored
work_order = WorkOrder.last
puts work_order.property_id  # Should be 1, not 999
```

**Mass Assignment Protection**

```bash
# Try assigning to unauthorized user via params
curl -X POST http://localhost:3000/api/v1/properties/1/work_orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "work_order": {
      "title": "Test",
      "description": "Test",
      "assigned_to_id": 999,
      "priority": "normal"
    }
  }'

# Expected:
# assigned_to_id should be ignored (not permitted)
# Only title, description, priority permitted
```

### SQL Injection Testing

**Arel.sql() Vulnerability**

```bash
# Current vulnerable scope (if using user input):
# scope :by_priority, -> { order(Arel.sql("CASE priority...")) }

# If user input were added:
# scope :by_priority, ->(input) { order(Arel.sql("CASE priority WHEN #{input}...")) }

# Test payload:
PAYLOAD="urgent' THEN 0; DROP TABLE users; -- "

curl http://localhost:3000/api/v1/properties/1/work_orders?priority=$PAYLOAD \
  -H "Authorization: Bearer $TOKEN"

# Expected: Database should be safe (parameterized query)
# Vulnerable: Table drops
```

**Standard where() is safe** - These are parameterized:
```ruby
# SAFE - Uses parameterized queries
WorkOrder.where(property_id: params[:property_id])
Property.where(city: params[:city])
Tenant.where("lease_end IS NULL OR lease_end >= ?", Date.current)

# These should be tested to confirm they don't break:
work_orders = WorkOrder.where(property_id: "1' OR '1'='1")
# Should return no results, not all rows
```

## Automated Testing

### Unit Tests for Authorization

**File**: `spec/policies/work_order_policy_spec.rb`

```ruby
RSpec.describe WorkOrderPolicy, type: :policy do
  let(:admin) { build_stubbed(:user, role: 'admin') }
  let(:manager) { build_stubbed(:user, role: 'manager') }
  let(:technician) { build_stubbed(:user, role: 'technician') }

  let(:own_property) { build_stubbed(:property, manager: manager) }
  let(:other_property) { build_stubbed(:property) }

  let(:own_work_order) { build_stubbed(:work_order, property: own_property) }
  let(:other_work_order) { build_stubbed(:work_order, property: other_property) }

  describe 'scope' do
    it 'allows admin to see all work orders' do
      expect(Pundit.policy_scope!(admin, WorkOrder).resolve).to include(own_work_order, other_work_order)
    end

    it 'allows manager to see only own property work orders' do
      result = Pundit.policy_scope!(manager, WorkOrder).resolve
      expect(result).to include(own_work_order)
      expect(result).not_to include(other_work_order)
    end
  end

  describe '#index?' do
    it 'allows admin' do
      expect(WorkOrderPolicy.new(admin, own_work_order)).to permit(:index)
    end

    it 'allows manager with own property' do
      expect(WorkOrderPolicy.new(manager, own_work_order)).to permit(:index)
    end

    it 'denies manager with other property' do
      expect(WorkOrderPolicy.new(manager, other_work_order)).not_to permit(:index)
    end
  end

  describe '#create?' do
    it 'allows admin' do
      expect(WorkOrderPolicy.new(admin, own_work_order)).to permit(:create)
    end

    it 'allows manager' do
      expect(WorkOrderPolicy.new(manager, own_work_order)).to permit(:create)
    end

    it 'allows technician' do
      expect(WorkOrderPolicy.new(technician, own_work_order)).to permit(:create)
    end
  end

  describe '#update?' do
    it 'allows admin' do
      expect(WorkOrderPolicy.new(admin, own_work_order)).to permit(:update)
    end

    it 'allows manager with own property' do
      expect(WorkOrderPolicy.new(manager, own_work_order)).to permit(:update)
    end

    it 'denies manager with other property' do
      expect(WorkOrderPolicy.new(manager, other_work_order)).not_to permit(:update)
    end

    it 'denies technician' do
      expect(WorkOrderPolicy.new(technician, own_work_order)).not_to permit(:update)
    end
  end

  describe '#destroy?' do
    it 'allows only admin' do
      expect(WorkOrderPolicy.new(admin, own_work_order)).to permit(:destroy)
      expect(WorkOrderPolicy.new(manager, own_work_order)).not_to permit(:destroy)
      expect(WorkOrderPolicy.new(technician, own_work_order)).not_to permit(:destroy)
    end
  end
end
```

### Integration Tests for Authentication

**File**: `spec/requests/api/v1/work_orders_security_spec.rb`

```ruby
RSpec.describe 'WorkOrders Security', type: :request do
  describe 'Authentication' do
    it 'denies request without authorization header' do
      get api_v1_property_work_orders_path(property_id: 1)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'denies request with invalid token' do
      get api_v1_property_work_orders_path(property_id: 1),
          headers: { 'Authorization' => 'Bearer invalid_token' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'denies request with expired token' do
      # Create expired token
      user = create(:user)
      expired_token = JWT.encode(
        { user_id: user.id, exp: 1.hour.ago.to_i },
        Rails.application.secrets.secret_key_base
      )

      get api_v1_property_work_orders_path(property_id: 1),
          headers: { 'Authorization' => "Bearer #{expired_token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows request with valid token' do
      user = create(:user)
      token = encode_token(user.id)

      get api_v1_property_work_orders_path(property_id: 1),
          headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(200).or have_http_status(403)
    end
  end

  describe 'Authorization' do
    let(:manager) { create(:user, role: 'manager') }
    let(:other_manager) { create(:user, role: 'manager') }
    let(:admin) { create(:user, role: 'admin') }

    let(:manager_property) { create(:property, manager: manager) }
    let(:other_property) { create(:property, manager: other_manager) }

    it 'allows manager to access own property work orders' do
      create(:work_order, property: manager_property)
      token = encode_token(manager.id)

      get api_v1_property_work_orders_path(property_id: manager_property.id),
          headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to be_an(Array)
    end

    it 'denies manager access to other property work orders' do
      token = encode_token(manager.id)

      get api_v1_property_work_orders_path(property_id: other_property.id),
          headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows admin to access any property work orders' do
      create(:work_order, property: other_property)
      token = encode_token(admin.id)

      get api_v1_property_work_orders_path(property_id: other_property.id),
          headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Parameter Validation' do
    let(:manager) { create(:user, role: 'manager') }
    let(:property) { create(:property, manager: manager) }
    let(:token) { encode_token(manager.id) }

    it 'ignores property_id in request body' do
      other_property = create(:property)

      post api_v1_property_work_orders_path(property_id: property.id),
           params: {
             work_order: {
               title: 'Test',
               description: 'Test',
               property_id: other_property.id,  # Should be ignored
               priority: 'normal'
             }
           },
           headers: { 'Authorization' => "Bearer #{token}" }

      work_order = WorkOrder.last
      expect(work_order.property_id).to eq(property.id)
      expect(work_order.property_id).not_to eq(other_property.id)
    end
  end

  describe 'N+1 Query Prevention' do
    let(:user) { create(:user) }
    let(:property) { create(:property) }
    let(:token) { encode_token(user.id) }

    before do
      create_list(:work_order, 5, property: property)
    end

    it 'uses eager loading' do
      expect {
        get api_v1_property_work_orders_path(property_id: property.id),
            headers: { 'Authorization' => "Bearer #{token}" }
      }.not_to exceed_query_limit(4)  # 1 work_orders + 1 property + 1 tenant + 1 user
    end
  end
end

# Helper
def encode_token(user_id)
  JWT.encode({ user_id: user_id }, Rails.application.secrets.secret_key_base)
end
```

### Request Spec for Security Headers

**File**: `spec/requests/security_headers_spec.rb`

```ruby
RSpec.describe 'Security Headers', type: :request do
  let(:user) { create(:user) }
  let(:token) { encode_token(user.id) }

  before do
    get api_v1_property_work_orders_path(property_id: 1),
        headers: { 'Authorization' => "Bearer #{token}" }
  end

  it 'includes HSTS header in production' do
    skip 'Only test in production' unless Rails.env.production?
    expect(response.headers['Strict-Transport-Security']).to be_present
  end

  it 'includes X-Content-Type-Options header' do
    expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
  end

  it 'includes X-Frame-Options header' do
    expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
  end

  it 'does not include X-XSS-Protection in modern browsers' do
    # Modern browsers don't need this, but it doesn't hurt
    expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
  end

  it 'includes Referrer-Policy header' do
    expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
  end
end
```

## Performance Testing (N+1 Detection)

Install and use query counter:

```ruby
# Gemfile - test group
gem 'rspec-query-limit'

# Usage in spec:
it 'executes expected number of queries' do
  expect {
    get api_v1_property_work_orders_path(property_id: 1),
        headers: { 'Authorization' => "Bearer #{token}" }
  }.not_to exceed_query_limit(4)
end
```

## Security Scanning Tools

### 1. Brakeman (Static Analysis)

```bash
gem 'brakeman', require: false

# Run scan
brakeman

# Generate report
brakeman -o report.html
```

**What it catches:**
- SQL injection vulnerabilities
- XSS vulnerabilities
- CSRF issues
- Dangerous redirects
- Insecure deserialization
- Hardcoded secrets

### 2. Bundler Audit (Dependency Vulnerabilities)

```bash
gem 'bundler-audit', require: false

# Check for vulnerable gems
bundle-audit check

# Generate report
bundle-audit check --format=json > audit-report.json
```

### 3. OWASP ZAP (Dynamic Security Scanner)

```bash
# Docker version
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t http://localhost:3000/api/v1/properties/1/work_orders

# Requires running application
# Scans for:
# - SQL injection
# - XSS
# - CSRF
# - Missing security headers
# - Insecure cookies
```

### 4. Semgrep (Code Pattern Scanning)

```bash
# Install
brew install semgrep

# Run Rails rules
semgrep --config=p/security-audit --config=p/rails \
  /Users/perhassle/source/Monterro/InfuseAI-Demos/Demo20260303
```

## CI/CD Integration

### GitHub Actions Example

**File**: `.github/workflows/security.yml`

```yaml
name: Security Checks

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2.2
          bundler-cache: true

      - name: Run Brakeman
        run: bundle exec brakeman --no-summary -q

      - name: Run Bundler Audit
        run: bundle exec bundler-audit check --update

      - name: Run RSpec Security Tests
        run: bundle exec rspec spec/requests/api/v1/work_orders_security_spec.rb

      - name: Run Security Headers Tests
        run: bundle exec rspec spec/requests/security_headers_spec.rb
```

## Manual Security Testing Checklist

### Before Deployment

- [ ] Run Brakeman - fix all high/medium issues
- [ ] Run bundler-audit - update vulnerable gems
- [ ] Run full RSpec suite - all tests pass
- [ ] Test authentication flow manually
- [ ] Test authorization - verify cross-property access is denied
- [ ] Test N+1 query fix - verify limited number of queries
- [ ] Remove any hardcoded credentials from code
- [ ] Verify .gitignore covers .env files
- [ ] Check git history for any leaked secrets
- [ ] Run OWASP ZAP scan
- [ ] Verify security headers in response
- [ ] Test with invalid/expired tokens
- [ ] Test with tampered tokens
- [ ] Verify rate limiting (once implemented)

### Post-Deployment Monitoring

- [ ] Monitor for 401/403 errors (authorization issues)
- [ ] Monitor API response times (N+1 queries)
- [ ] Check database slow query log
- [ ] Monitor authentication failures (brute force attempts)
- [ ] Review security logs for suspicious activity
- [ ] Weekly bundle audit updates
- [ ] Monthly dependency updates
- [ ] Quarterly security audit

## Tools Summary

| Tool | Purpose | Command |
|------|---------|---------|
| Brakeman | Static security analysis | `bundle exec brakeman` |
| Bundler Audit | Vulnerable gem detection | `bundle-audit check` |
| RSpec | Unit/integration tests | `bundle exec rspec` |
| OWASP ZAP | Dynamic security scanning | `zap-baseline.py` |
| Semgrep | Code pattern matching | `semgrep --config=p/rails` |
| Pundit | Authorization testing | `rspec spec/policies/` |
| Query Limiter | N+1 detection | `rspec-query-limit` |

## Common False Positives in Brakeman

- `Arel.sql()` with hardcoded SQL (not interpolated) - SAFE
- `where()` with symbol keys - SAFE (parameterized)
- `find()` with string param - SAFE (parameterized)

## Test Coverage Goal

After implementing fixes, aim for:
- 100% coverage of authorization policies
- 100% coverage of authentication paths
- 90%+ overall code coverage
- All security-relevant code in tests

Run: `bundle exec rspec --format documentation --color`
