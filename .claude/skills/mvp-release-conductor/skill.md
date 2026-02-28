# MVP Release Conductor

Orchestrates backend MVP releases by automating task delegation to specialist skills, ensuring a coordinated, efficient release process for the Rentable API-only backend.

## Description

This skill acts as a **release automation conductor** that:
- Coordinates all specialist skills (backend-developer, qa-tester, devops-engineer, etc.)
- Executes a predefined MVP release checklist
- Automates repetitive tasks across skills
- Ensures quality gates are met before progression
- Provides real-time status and rollback capabilities
- Focuses exclusively on backend API releases (frontend separate)

**Think of this as your AI Release Manager** that knows when to call the backend developer, when to trigger QA tests, when to deploy, and when to verify—all automatically.

## When to Use

Use this skill when you need to:
- Release a backend MVP to production
- Execute a coordinated release workflow
- Automate the entire backend deployment pipeline
- Ensure all quality gates pass before production
- Coordinate multiple specialist skills in sequence
- Generate release documentation automatically
- Perform post-release verification

## MVP Release Workflow

The conductor executes these phases automatically:

```
Phase 1: PRE-RELEASE CHECKS
├─> [database-administrator] Verify database ready
├─> [backend-developer] Run code audit
├─> [security-engineer] Security scan
└─> [technical-architect] Architecture review

Phase 2: TESTING
├─> [qa-tester] Run full test suite
├─> [api-tester] API contract testing
├─> [qa-tester] Load testing
└─> [qa-tester] Security testing

Phase 3: DEPLOYMENT
├─> [devops-engineer] Deploy to staging
├─> [api-tester] Staging smoke tests
├─> [devops-engineer] Deploy to production
└─> [api-tester] Production smoke tests

Phase 4: POST-RELEASE
├─> [devops-engineer] Monitor metrics
├─> [database-administrator] Database health check
├─> [api-tester] End-to-end verification
└─> [project-manager] Release report
```

## Core Commands

### 1. Full MVP Release (Automated)

```bash
# Single command to release MVP
claude mvp-release-conductor --release-mvp --version "v1.0.0"

# This internally executes:
# 1. Pre-release checks (all skills)
# 2. Automated testing (qa-tester, api-tester)
# 3. Deployment (devops-engineer)
# 4. Post-release verification (api-tester, devops-engineer)
# 5. Documentation (project-manager)
```

**What happens behind the scenes:**

```ruby
# Conductor orchestrates these skill calls:

# PHASE 1: PRE-RELEASE CHECKS
@database_administrator.verify_production_ready
# -> Checks migrations, indexes, backups

@backend_developer.code_audit
# -> Reviews recent commits, checks test coverage

@security_engineer.security_scan
# -> Runs Brakeman, bundle audit, secret scanning

@technical_architect.architecture_review
# -> Validates API versioning, backward compatibility

# PHASE 2: TESTING (parallel where possible)
@qa_tester.run_full_test_suite
# -> RSpec, integration tests, 95%+ coverage required

@api_tester.contract_testing
# -> Validates all API endpoints against OpenAPI spec

@qa_tester.load_testing
# -> k6 load test: 100 concurrent users, <500ms response

@qa_tester.security_testing
# -> OWASP Top 10 checks

# PHASE 3: DEPLOYMENT
@devops_engineer.deploy_to_staging
# -> Docker build, staging deployment

@api_tester.staging_smoke_tests
# -> Critical path testing on staging

# QUALITY GATE: If staging tests pass
@devops_engineer.deploy_to_production
# -> Blue-green deployment to production

@api_tester.production_smoke_tests
# -> Verify production endpoints responding

# PHASE 4: POST-RELEASE
@devops_engineer.monitor_metrics(duration: '15m')
# -> Watch error rates, response times, CPU/memory

@database_administrator.health_check
# -> Query performance, connection pool

@api_tester.end_to_end_verification
# -> Full user journey testing

@project_manager.generate_release_report
# -> Document what was released, metrics, issues
```

### 2. Release with Custom Phases

```bash
# Run specific phases only
claude mvp-release-conductor --phase pre-release
claude mvp-release-conductor --phase testing
claude mvp-release-conductor --phase deployment
claude mvp-release-conductor --phase post-release
```

### 3. Automated Rollback

```bash
# If any phase fails, automatic rollback
claude mvp-release-conductor --rollback --to-version "v0.9.0"

# This calls:
# @devops_engineer.rollback_deployment(version: 'v0.9.0')
# @database_administrator.rollback_migrations
# @api_tester.verify_rollback_successful
```

## Real-World Usage Example

### Example 1: MVP Release for Rentable Backend v1.0

```bash
# Start the automated release
bin/rails runner <<'RUBY'
require 'mvp_release_conductor'

conductor = MvpReleaseConductor.new(
  version: 'v1.0.0',
  release_manager: 'victor@rentable.com',
  target_environment: 'production'
)

# Execute automated release
result = conductor.release!

# Conductor output:
#
# ╔════════════════════════════════════════════════════════════════╗
# ║           MVP RELEASE CONDUCTOR - v1.0.0                       ║
# ╚════════════════════════════════════════════════════════════════╝
#
# [09:00:00] ✓ Phase 1: PRE-RELEASE CHECKS
#   [09:00:05] ✓ database-administrator: Database ready
#   [09:00:15] ✓ backend-developer: Code audit passed
#   [09:00:25] ✓ security-engineer: No vulnerabilities found
#   [09:00:35] ✓ technical-architect: Architecture approved
#
# [09:00:40] ✓ Phase 2: TESTING
#   [09:01:00] ✓ qa-tester: 1,247 tests passed (96% coverage)
#   [09:02:00] ✓ api-tester: 87 endpoints verified
#   [09:03:00] ✓ qa-tester: Load test passed (avg 235ms)
#   [09:03:30] ✓ qa-tester: Security tests passed
#
# [09:03:35] ✓ Phase 3: DEPLOYMENT
#   [09:05:00] ✓ devops-engineer: Staging deployed
#   [09:06:00] ✓ api-tester: Staging smoke tests passed
#   [09:08:00] ✓ devops-engineer: Production deployed (blue-green)
#   [09:09:00] ✓ api-tester: Production smoke tests passed
#
# [09:09:05] ✓ Phase 4: POST-RELEASE
#   [09:24:00] ✓ devops-engineer: 15-min monitoring OK
#   [09:24:30] ✓ database-administrator: Database healthy
#   [09:25:00] ✓ api-tester: E2E verification passed
#   [09:26:00] ✓ project-manager: Release report generated
#
# ╔════════════════════════════════════════════════════════════════╗
# ║              🎉 RELEASE SUCCESSFUL - v1.0.0 🎉                 ║
# ╚════════════════════════════════════════════════════════════════╝
#
# Release Duration: 26 minutes
# Features Released: 12
# Tests Passed: 1,247
# API Endpoints: 87
# Deployment Method: Blue-Green
# Rollback Available: Yes (v0.9.0)
#
# Release URL: https://api.rentable.com/v1
# Documentation: https://docs.rentable.com/releases/v1.0.0
# Status Dashboard: https://status.rentable.com

RUBY
```

### Example 2: Hotfix Release (Fast Track)

```bash
# Emergency bug fix release (skips some checks)
bin/rails runner <<'RUBY'
conductor = MvpReleaseConductor.new(
  version: 'v1.0.1',
  release_type: :hotfix,
  skip_phases: [:load_testing, :architecture_review]
)

result = conductor.release!
# Only runs critical phases: security scan, tests, deployment, monitoring
RUBY
```

### Example 3: Staged Rollout (Canary)

```bash
# Release to 10% of traffic first
bin/rails runner <<'RUBY'
conductor = MvpReleaseConductor.new(
  version: 'v1.1.0',
  deployment_strategy: :canary,
  canary_percentage: 10
)

# Deploy to 10%
conductor.deploy_canary!
# Monitor for 1 hour
sleep(3600)
# If metrics good, promote to 100%
conductor.promote_canary_to_full!
RUBY
```

## Detailed Phase Breakdowns

### Phase 1: Pre-Release Checks

```ruby
class PreReleaseChecks
  def execute
    puts "╔════════════════════════════════════════════════════════════════╗"
    puts "║              PHASE 1: PRE-RELEASE CHECKS                       ║"
    puts "╚════════════════════════════════════════════════════════════════╝"

    # Check 1: Database Ready
    database_check = @database_administrator.execute(<<~RUBY)
      # Verify migrations
      pending = ActiveRecord::Base.connection.migration_context.needs_migration?
      raise "Pending migrations!" if pending

      # Verify indexes exist
      critical_indexes = [
        'index_bookings_on_company_id',
        'index_products_on_company_id',
        'index_users_on_email'
      ]

      critical_indexes.each do |index_name|
        exists = ActiveRecord::Base.connection.indexes('bookings').any? { |i| i.name == index_name }
        raise "Missing index: #{index_name}" unless exists
      end

      # Verify backup recent
      last_backup = `aws s3 ls s3://rentable-backups/production/ | tail -1`
      backup_time = Time.parse(last_backup.split[0..1].join(' '))
      raise "Backup older than 24 hours" if backup_time < 24.hours.ago

      { status: 'passed', message: 'Database ready for release' }
    RUBY

    # Check 2: Code Quality
    code_audit = @backend_developer.execute(<<~RUBY)
      # Test coverage
      system('COVERAGE=true bundle exec rspec')
      coverage = SimpleCov.result.covered_percent
      raise "Coverage below 95%: #{coverage}%" if coverage < 95

      # Rubocop violations
      result = system('bundle exec rubocop')
      raise "Rubocop violations found" unless result

      # Bundle audit (security vulnerabilities)
      result = system('bundle audit check --update')
      raise "Vulnerable gems found" unless result

      { status: 'passed', coverage: coverage }
    RUBY

    # Check 3: Security Scan
    security_scan = @security_engineer.execute(<<~RUBY)
      # Brakeman security scan
      result = system('bundle exec brakeman --no-pager --quiet')
      raise "Security vulnerabilities found" unless result

      # Secret scanning
      secrets = `git secrets --scan`
      raise "Secrets detected in code" if $?.exitstatus != 0

      # Check for exposed .env files
      raise ".env in git" if File.exist?('.env') && `git ls-files .env`.present?

      { status: 'passed', message: 'No security issues' }
    RUBY

    # Check 4: Architecture Review
    arch_review = @technical_architect.execute(<<~RUBY)
      # Verify API versioning
      routes = Rails.application.routes.routes
      api_routes = routes.select { |r| r.path.spec.to_s.include?('/api/') }
      unversioned = api_routes.reject { |r| r.path.spec.to_s.match?(/\/v\d+\//) }
      raise "Unversioned API routes found" if unversioned.any?

      # Check backward compatibility
      breaking_changes = `git diff v0.9.0..HEAD -- app/controllers/api/`
      if breaking_changes.include?('def destroy') || breaking_changes.include?('remove_column')
        puts "⚠️  WARNING: Potential breaking changes detected"
      end

      { status: 'passed', api_version: 'v1' }
    RUBY

    all_passed = [database_check, code_audit, security_scan, arch_review].all? do |check|
      check[:status] == 'passed'
    end

    raise "Pre-release checks failed" unless all_passed

    puts "✅ All pre-release checks passed"
  end
end
```

### Phase 2: Automated Testing

```ruby
class AutomatedTesting
  def execute
    puts "╔════════════════════════════════════════════════════════════════╗"
    puts "║                  PHASE 2: TESTING                              ║"
    puts "╚════════════════════════════════════════════════════════════════╝"

    # Test 1: Full Test Suite
    test_suite = @qa_tester.execute(<<~BASH)
      # Run full RSpec suite
      bundle exec rspec --format documentation --format json --out tmp/rspec.json

      # Parse results
      results=$(cat tmp/rspec.json)
      total=$(echo $results | jq '.summary.example_count')
      failures=$(echo $results | jq '.summary.failure_count')

      if [ $failures -gt 0 ]; then
        echo "❌ $failures tests failed"
        exit 1
      fi

      echo "✅ All $total tests passed"
    BASH

    # Test 2: API Contract Testing
    api_contract = @api_tester.execute(<<~RUBY)
      require 'api_contract_validator'

      validator = ApiContractValidator.new('config/openapi.yml')

      # Test all endpoints against OpenAPI spec
      endpoints = [
        { method: :get, path: '/api/v1/products' },
        { method: :post, path: '/api/v1/products' },
        { method: :get, path: '/api/v1/bookings' },
        { method: :post, path: '/api/v1/bookings' },
        # ... all 87 endpoints
      ]

      results = endpoints.map do |endpoint|
        validator.validate(endpoint[:method], endpoint[:path])
      end

      failures = results.select { |r| !r[:valid] }
      raise "API contract violations: #{failures}" if failures.any?

      { status: 'passed', endpoints_tested: endpoints.count }
    RUBY

    # Test 3: Load Testing
    load_test = @qa_tester.execute(<<~BASH)
      # Run k6 load test
      k6 run --vus 100 --duration 5m tests/load/api_load_test.js --out json=tmp/k6.json

      # Check results
      avg_response=$(cat tmp/k6.json | jq -r '.metrics.http_req_duration.values.avg')
      p95_response=$(cat tmp/k6.json | jq -r '.metrics.http_req_duration.values["p(95)"]')
      error_rate=$(cat tmp/k6.json | jq -r '.metrics.http_req_failed.values.rate')

      # Quality gates
      if (( $(echo "$avg_response > 500" | bc -l) )); then
        echo "❌ Average response time too high: ${avg_response}ms"
        exit 1
      fi

      if (( $(echo "$error_rate > 0.01" | bc -l) )); then
        echo "❌ Error rate too high: ${error_rate}%"
        exit 1
      fi

      echo "✅ Load test passed (avg: ${avg_response}ms, p95: ${p95_response}ms)"
    BASH

    # Test 4: Security Testing (OWASP)
    security_test = @qa_tester.execute(<<~BASH)
      # Run OWASP ZAP security scan
      docker run -t owasp/zap2docker-stable zap-baseline.py \
        -t http://staging.rentable.com/api/v1 \
        -r zap_report.html

      # Check for high/medium vulnerabilities
      if grep -q "FAIL-NEW" zap_report.html; then
        echo "❌ Security vulnerabilities found"
        exit 1
      fi

      echo "✅ No security issues detected"
    BASH

    puts "✅ All testing phases passed"
  end
end
```

### Phase 3: Deployment

```ruby
class DeploymentPhase
  def execute
    puts "╔════════════════════════════════════════════════════════════════╗"
    puts "║                  PHASE 3: DEPLOYMENT                           ║"
    puts "╚════════════════════════════════════════════════════════════════╝"

    # Step 1: Deploy to Staging
    staging = @devops_engineer.execute(<<~BASH)
      # Build Docker image
      docker build -t rentable-api:v1.0.0 .

      # Tag for staging
      docker tag rentable-api:v1.0.0 registry.rentable.com/api:staging

      # Push to registry
      docker push registry.rentable.com/api:staging

      # Deploy to staging (ECS/Kubernetes)
      kubectl set image deployment/rentable-api \
        rentable-api=registry.rentable.com/api:staging \
        --namespace=staging

      # Wait for rollout
      kubectl rollout status deployment/rentable-api --namespace=staging --timeout=5m

      echo "✅ Staging deployed successfully"
    BASH

    # Step 2: Staging Smoke Tests
    staging_tests = @api_tester.execute(<<~RUBY)
      base_url = 'https://staging-api.rentable.com'
      token = User.first.generate_jwt

      # Critical path tests
      tests = [
        { name: 'Health Check', path: '/health', expected: 200 },
        { name: 'List Products', path: '/api/v1/products', expected: 200 },
        { name: 'Create Booking', path: '/api/v1/bookings', method: :post, expected: 201 },
        { name: 'Get Booking', path: '/api/v1/bookings/1', expected: 200 }
      ]

      tests.each do |test|
        response = HTTParty.send(
          test[:method] || :get,
          "#{base_url}#{test[:path]}",
          headers: { 'Authorization' => "Bearer #{token}" }
        )

        unless response.code == test[:expected]
          raise "#{test[:name]} failed: expected #{test[:expected]}, got #{response.code}"
        end

        puts "  ✓ #{test[:name]}"
      end

      { status: 'passed', tests_run: tests.count }
    RUBY

    puts "\n⚠️  PRODUCTION DEPLOYMENT GATE"
    puts "Staging tests passed. Proceeding to production...\n"
    sleep(2)

    # Step 3: Deploy to Production (Blue-Green)
    production = @devops_engineer.execute(<<~BASH)
      # Tag for production
      docker tag rentable-api:v1.0.0 registry.rentable.com/api:v1.0.0
      docker push registry.rentable.com/api:v1.0.0

      # Blue-green deployment
      # Current production = blue
      # Deploy new version to green
      kubectl apply -f k8s/deployment-green.yml --namespace=production

      # Wait for green to be ready
      kubectl wait --for=condition=available --timeout=5m \
        deployment/rentable-api-green --namespace=production

      # Switch traffic to green (0% -> 100% over 5 minutes)
      kubectl apply -f k8s/service-green.yml --namespace=production

      # Keep blue running for 15 min (rollback safety)
      echo "✅ Production deployed (blue-green)"
      echo "   Blue (old): kept running for 15 min"
      echo "   Green (new): v1.0.0 receiving 100% traffic"
    BASH

    # Step 4: Production Smoke Tests
    production_tests = @api_tester.execute(<<~RUBY)
      base_url = 'https://api.rentable.com'

      # Same critical path tests on production
      tests = [
        { name: 'Health Check', path: '/health', expected: 200 },
        { name: 'List Products', path: '/api/v1/products', expected: 200 },
        { name: 'API Version', path: '/api/v1/version', expected: 200 }
      ]

      tests.each do |test|
        response = HTTParty.get("#{base_url}#{test[:path]}")

        unless response.code == test[:expected]
          # CRITICAL: Production smoke test failed - trigger rollback
          @devops_engineer.rollback_to_blue!
          raise "PRODUCTION SMOKE TEST FAILED: #{test[:name]}"
        end

        puts "  ✓ #{test[:name]}"
      end

      { status: 'passed', production_verified: true }
    RUBY

    puts "✅ Production deployment successful"
  end
end
```

### Phase 4: Post-Release Monitoring

```ruby
class PostReleaseMonitoring
  def execute
    puts "╔════════════════════════════════════════════════════════════════╗"
    puts "║              PHASE 4: POST-RELEASE MONITORING                  ║"
    puts "╚════════════════════════════════════════════════════════════════╝"

    # Monitor 1: Application Metrics (15 minutes)
    metrics = @devops_engineer.execute(<<~RUBY)
      require 'prometheus/client'

      puts "Monitoring production for 15 minutes..."

      15.times do |minute|
        # Fetch metrics from Prometheus
        metrics = {
          error_rate: prometheus_query('rate(http_requests_total{status=~"5.."}[1m])'),
          response_time_p95: prometheus_query('histogram_quantile(0.95, http_request_duration_seconds)'),
          cpu_usage: prometheus_query('container_cpu_usage_seconds_total'),
          memory_usage: prometheus_query('container_memory_usage_bytes'),
          active_requests: prometheus_query('http_requests_in_flight')
        }

        # Quality gates
        if metrics[:error_rate] > 0.01  # >1% error rate
          puts "❌ ERROR RATE SPIKE: #{metrics[:error_rate]}%"
          @devops_engineer.rollback_to_blue!
          raise "Rollback triggered: High error rate"
        end

        if metrics[:response_time_p95] > 1000  # >1s p95
          puts "⚠️  WARNING: High response time: #{metrics[:response_time_p95]}ms"
        end

        puts "  [#{minute + 1}/15] Error: #{(metrics[:error_rate] * 100).round(3)}% | " \
             "P95: #{metrics[:response_time_p95].round(0)}ms | " \
             "CPU: #{metrics[:cpu_usage].round(1)}% | " \
             "Mem: #{(metrics[:memory_usage] / 1024 / 1024).round(0)}MB"

        sleep(60)
      end

      { status: 'passed', monitoring_duration: '15m' }
    RUBY

    # Monitor 2: Database Health
    db_health = @database_administrator.execute(<<~RUBY)
      # Connection pool health
      pool_stats = ActiveRecord::Base.connection_pool.stat
      raise "Connection pool exhausted" if pool_stats[:busy] > pool_stats[:size] * 0.9

      # Slow queries
      slow_queries = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT query, calls, mean_exec_time
        FROM pg_stat_statements
        WHERE mean_exec_time > 1000
        ORDER BY mean_exec_time DESC
        LIMIT 10
      SQL

      if slow_queries.any?
        puts "⚠️  WARNING: Slow queries detected"
        slow_queries.each do |q|
          puts "  #{q['query'][0..80]}... (#{q['mean_exec_time'].round(0)}ms avg)"
        end
      end

      # Database size growth
      db_size = ActiveRecord::Base.connection.execute("SELECT pg_database_size(current_database())").first['pg_database_size']
      puts "  Database size: #{(db_size / 1024.0 / 1024 / 1024).round(2)} GB"

      { status: 'passed', database_healthy: true }
    RUBY

    # Monitor 3: End-to-End Verification
    e2e = @api_tester.execute(<<~RUBY)
      # Full user journey test
      company = Company.first
      ActsAsTenant.with_tenant(company) do
        # Journey: Create booking -> Add items -> Process payment -> Confirm

        # 1. Create booking
        booking = Booking.create!(
          customer_name: 'E2E Test Customer',
          customer_email: 'e2e@test.com',
          start_date: 3.days.from_now,
          end_date: 5.days.from_now,
          status: :draft,
          client: company.clients.first
        )

        # 2. Add line items
        product = Product.active.first
        booking.booking_line_items.create!(
          bookable: product,
          quantity: 1,
          days: 2,
          price: product.daily_price
        )

        # 3. Calculate totals
        booking.calculate_total_price
        booking.save!

        # 4. Confirm booking
        booking.update!(status: :confirmed)

        # 5. Verify
        raise "Booking not confirmed" unless booking.confirmed?
        raise "Total price not calculated" unless booking.total_price_cents > 0

        # Cleanup
        booking.destroy

        puts "  ✓ Full booking journey successful"
      end

      { status: 'passed', e2e_verified: true }
    RUBY

    # Monitor 4: Generate Release Report
    report = @project_manager.execute(<<~RUBY)
      # Generate comprehensive release report
      report = {
        version: 'v1.0.0',
        released_at: Time.current,
        release_manager: 'victor@rentable.com',
        deployment_method: 'blue-green',
        duration: '26 minutes',

        features_released: [
          'Recurring bookings',
          'Smart pricing engine',
          'Customer self-service portal',
          'Weekend/holiday pricing',
          'Booking templates',
          'API performance optimization',
          # ... 12 total
        ],

        test_results: {
          total_tests: 1247,
          passed: 1247,
          failed: 0,
          coverage: 96.3
        },

        api_endpoints: {
          total: 87,
          new: 12,
          modified: 5,
          deprecated: 0
        },

        performance: {
          avg_response_time: '235ms',
          p95_response_time: '450ms',
          error_rate: '0.02%',
          throughput: '150 req/sec'
        },

        database: {
          migrations_run: 8,
          indexes_added: 5,
          size_gb: 2.4
        },

        rollback_plan: {
          available: true,
          previous_version: 'v0.9.0',
          method: 'Switch traffic to blue deployment'
        }
      }

      # Save to file
      File.write('releases/v1.0.0_report.json', JSON.pretty_generate(report))

      puts "\n" + "=" * 70
      puts "RELEASE REPORT - v1.0.0"
      puts "=" * 70
      puts JSON.pretty_generate(report)
      puts "=" * 70

      report
    RUBY

    puts "✅ Post-release monitoring complete"
  end
end
```

## Configuration File

Create `.claude/mvp-release-config.yml`:

```yaml
# MVP Release Conductor Configuration

release:
  version: v1.0.0
  release_manager: victor@rentable.com

environments:
  staging:
    url: https://staging-api.rentable.com
    database: rentable_staging

  production:
    url: https://api.rentable.com
    database: rentable_production

deployment:
  strategy: blue-green  # or: rolling, canary
  health_check_url: /health
  rollback_on_error: true
  keep_old_version_minutes: 15

quality_gates:
  test_coverage_min: 95
  error_rate_max: 0.01
  response_time_p95_max: 500
  security_vulnerabilities_max: 0

monitoring:
  post_release_duration_minutes: 15
  alert_channels:
    - slack: "#releases"
    - email: "team@rentable.com"

phases:
  pre_release:
    enabled: true
    checks:
      - database_ready
      - code_audit
      - security_scan
      - architecture_review

  testing:
    enabled: true
    parallel: true
    tests:
      - full_test_suite
      - api_contract
      - load_testing
      - security_testing

  deployment:
    enabled: true
    steps:
      - deploy_staging
      - staging_smoke_tests
      - deploy_production
      - production_smoke_tests

  post_release:
    enabled: true
    monitoring:
      - application_metrics
      - database_health
      - e2e_verification
      - generate_report

rollback:
  automatic: true
  triggers:
    - error_rate > 1%
    - response_time_p95 > 2000ms
    - smoke_tests_failed
```

## Implementation Code

Create `lib/mvp_release_conductor.rb`:

```ruby
# lib/mvp_release_conductor.rb

class MvpReleaseConductor
  attr_reader :version, :config, :phase_results

  def initialize(version:, release_manager: nil, target_environment: 'production', release_type: :standard)
    @version = version
    @release_manager = release_manager
    @target_environment = target_environment
    @release_type = release_type
    @config = YAML.load_file('.claude/mvp-release-config.yml')
    @phase_results = {}

    # Initialize specialist skills
    @database_administrator = SkillExecutor.new('database-administrator')
    @backend_developer = SkillExecutor.new('backend-developer')
    @security_engineer = SkillExecutor.new('security-engineer')
    @technical_architect = SkillExecutor.new('technical-architect')
    @qa_tester = SkillExecutor.new('qa-tester')
    @api_tester = SkillExecutor.new('api-tester')
    @devops_engineer = SkillExecutor.new('devops-engineer')
    @project_manager = SkillExecutor.new('project-manager')
  end

  def release!
    puts release_header

    start_time = Time.current

    begin
      # Execute all phases
      phase_1_pre_release if config.dig('phases', 'pre_release', 'enabled')
      phase_2_testing if config.dig('phases', 'testing', 'enabled')
      phase_3_deployment if config.dig('phases', 'deployment', 'enabled')
      phase_4_post_release if config.dig('phases', 'post_release', 'enabled')

      duration = (Time.current - start_time).to_i / 60

      success_banner(duration)

      { success: true, duration_minutes: duration, version: @version }
    rescue => e
      puts "\n❌ RELEASE FAILED: #{e.message}\n"

      # Automatic rollback if configured
      if config.dig('rollback', 'automatic')
        puts "\n🔄 Initiating automatic rollback...\n"
        rollback!
      end

      { success: false, error: e.message }
    end
  end

  private

  def phase_1_pre_release
    puts "\n#{phase_header('PHASE 1: PRE-RELEASE CHECKS')}\n"

    PreReleaseChecks.new(
      database_administrator: @database_administrator,
      backend_developer: @backend_developer,
      security_engineer: @security_engineer,
      technical_architect: @technical_architect
    ).execute

    @phase_results[:pre_release] = { status: 'passed', completed_at: Time.current }
  end

  def phase_2_testing
    puts "\n#{phase_header('PHASE 2: TESTING')}\n"

    AutomatedTesting.new(
      qa_tester: @qa_tester,
      api_tester: @api_tester,
      config: @config
    ).execute

    @phase_results[:testing] = { status: 'passed', completed_at: Time.current }
  end

  def phase_3_deployment
    puts "\n#{phase_header('PHASE 3: DEPLOYMENT')}\n"

    DeploymentPhase.new(
      devops_engineer: @devops_engineer,
      api_tester: @api_tester,
      version: @version,
      environment: @target_environment,
      strategy: config.dig('deployment', 'strategy')
    ).execute

    @phase_results[:deployment] = { status: 'passed', completed_at: Time.current }
  end

  def phase_4_post_release
    puts "\n#{phase_header('PHASE 4: POST-RELEASE MONITORING')}\n"

    PostReleaseMonitoring.new(
      devops_engineer: @devops_engineer,
      database_administrator: @database_administrator,
      api_tester: @api_tester,
      project_manager: @project_manager,
      version: @version,
      duration_minutes: config.dig('monitoring', 'post_release_duration_minutes')
    ).execute

    @phase_results[:post_release] = { status: 'passed', completed_at: Time.current }
  end

  def rollback!(to_version: nil)
    puts "\n🔄 ROLLBACK INITIATED\n"

    # Rollback deployment
    @devops_engineer.rollback_deployment(version: to_version || previous_version)

    # Verify rollback
    @api_tester.verify_rollback_successful

    puts "✅ Rollback completed successfully"
  end

  def release_header
    <<~HEADER

    ╔════════════════════════════════════════════════════════════════╗
    ║           MVP RELEASE CONDUCTOR - #{@version.ljust(16)}             ║
    ╚════════════════════════════════════════════════════════════════╝

    Release Manager: #{@release_manager}
    Target Environment: #{@target_environment}
    Release Type: #{@release_type}
    Started: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}

    HEADER
  end

  def phase_header(title)
    "╔══ #{title} #{'═' * (60 - title.length)}╗"
  end

  def success_banner(duration_minutes)
    puts "\n"
    puts "╔════════════════════════════════════════════════════════════════╗"
    puts "║              🎉 RELEASE SUCCESSFUL - #{@version} 🎉                 ║"
    puts "╚════════════════════════════════════════════════════════════════╝"
    puts "\nRelease Duration: #{duration_minutes} minutes"
    puts "Completed: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "\n✅ All phases completed successfully"
  end
end

# Helper class to execute skill commands
class SkillExecutor
  def initialize(skill_name)
    @skill_name = skill_name
  end

  def execute(command)
    # Execute command in context of the skill
    eval(command)
  rescue => e
    raise "#{@skill_name} failed: #{e.message}"
  end
end
```

## Quick Start for MVP Release

### 1. One-Command Release

```bash
# Complete automated release
bin/rails runner "MvpReleaseConductor.new(version: 'v1.0.0').release!"
```

### 2. Release with Custom Config

```bash
# Create release with specific settings
bin/rails runner <<'RUBY'
conductor = MvpReleaseConductor.new(
  version: ENV['RELEASE_VERSION'] || 'v1.0.0',
  release_manager: `git config user.email`.strip,
  target_environment: ENV['TARGET_ENV'] || 'production',
  release_type: ENV['RELEASE_TYPE']&.to_sym || :standard
)

result = conductor.release!

if result[:success]
  puts "\n✅ Release completed in #{result[:duration_minutes]} minutes"
  exit 0
else
  puts "\n❌ Release failed: #{result[:error]}"
  exit 1
end
RUBY
```

### 3. CI/CD Integration

```yaml
# .github/workflows/release.yml
name: MVP Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., v1.0.0)'
        required: true

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.2

      - name: Install dependencies
        run: bundle install

      - name: Run MVP Release Conductor
        env:
          RELEASE_VERSION: ${{ github.event.inputs.version }}
          RELEASE_MANAGER: ${{ github.actor }}
        run: |
          bin/rails runner "
            conductor = MvpReleaseConductor.new(
              version: ENV['RELEASE_VERSION'],
              release_manager: ENV['RELEASE_MANAGER']
            )

            result = conductor.release!
            exit(result[:success] ? 0 : 1)
          "
```

## Benefits of Using This Skill

### 1. **Fully Automated**
- No manual steps required
- Eliminates human error
- Repeatable process

### 2. **Quality Gates**
- Automatic rollback on failure
- Multiple verification points
- Test coverage enforcement

### 3. **Coordination**
- Orchestrates 8 specialist skills
- Parallel execution where possible
- Sequential dependencies managed

### 4. **Visibility**
- Real-time progress updates
- Comprehensive release reports
- Audit trail

### 5. **Safety**
- Blue-green deployment
- 15-minute monitoring window
- Instant rollback capability

## Related Skills

- [backend-developer](../backend-developer/skill.md) - Code quality and testing
- [qa-tester](../qa-tester/skill.md) - Test automation
- [api-tester](../api-tester/skill.md) - API verification
- [devops-engineer](../devops-engineer/skill.md) - Deployment automation
- [database-administrator](../database-administrator/skill.md) - Database readiness
- [security-engineer](../security-engineer/skill.md) - Security scanning
- [technical-architect](../technical-architect/skill.md) - Architecture review
- [project-manager](../project-manager/skill.md) - Release reporting

## Best Practices

1. **Always test in staging first** - Never skip staging deployment
2. **Monitor for 15+ minutes** - Don't declare success too early
3. **Keep rollback ready** - Maintain previous version for quick rollback
4. **Automate everything** - Manual steps introduce errors
5. **Document releases** - Generate comprehensive release reports
6. **Notify stakeholders** - Automated Slack/email notifications
7. **Measure metrics** - Track deployment frequency, MTTR, failure rate
8. **Learn from failures** - Post-mortem for failed releases
