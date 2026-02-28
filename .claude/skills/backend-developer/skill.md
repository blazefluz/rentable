# Backend Developer (Rails)

Expert Rails backend development for the Rentable equipment rental SaaS platform.

## Description

This skill provides expert backend development capabilities including:
- Rails model, controller, and service development
- RESTful API design and implementation
- Database schema design and migrations
- Background job processing
- Authentication and authorization
- Payment integration (Stripe)
- Performance optimization
- Code refactoring and optimization

## When to Use

Use this skill when you need to:
- Add new features or endpoints
- Create or modify database models
- Write database migrations
- Implement business logic
- Optimize database queries
- Add background jobs
- Integrate third-party services
- Debug and fix backend issues
- Refactor existing code

## Core Responsibilities

### 1. Model Development
- Create Active Record models
- Define associations and validations
- Implement scopes and class methods
- Add callbacks and hooks
- Monetize attributes
- Implement soft deletes

### 2. API Development
- Build RESTful controllers
- Implement JSON serialization
- Handle request validation
- Return proper HTTP status codes
- Version API endpoints
- Document API changes

### 3. Business Logic
- Implement service objects
- Create form objects
- Build query objects
- Design interactors
- Handle complex workflows

### 4. Database Management
- Design database schemas
- Write migrations
- Add indexes for performance
- Handle data migrations
- Optimize N+1 queries

## Commands & Examples

### Create a New Model
```ruby
# Generate model with migration
rails generate model EquipmentMaintenanceLog \
  product:references \
  maintenance_type:integer \
  performed_by:references \
  performed_at:datetime \
  cost_cents:integer \
  cost_currency:string \
  notes:text \
  next_service_date:date \
  company:references

# Migration file: db/migrate/XXXXXX_create_equipment_maintenance_logs.rb
class CreateEquipmentMaintenanceLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_maintenance_logs do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :maintenance_type, null: false
      t.references :performed_by, null: false, foreign_key: { to_table: :users }
      t.datetime :performed_at, null: false
      t.monetize :cost
      t.text :notes
      t.date :next_service_date
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end

    add_index :equipment_maintenance_logs, [:product_id, :performed_at]
    add_index :equipment_maintenance_logs, :company_id
  end
end

# Model: app/models/equipment_maintenance_log.rb
class EquipmentMaintenanceLog < ApplicationRecord
  include ActsAsTenant
  acts_as_tenant(:company)

  belongs_to :product
  belongs_to :performed_by, class_name: 'User'
  belongs_to :company

  monetize :cost_cents, allow_nil: true

  enum maintenance_type: {
    routine_service: 0,
    repair: 1,
    calibration: 2,
    cleaning: 3,
    inspection: 4,
    upgrade: 5
  }

  validates :product, :performed_by, :performed_at, :maintenance_type, presence: true
  validates :cost_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :recent, -> { order(performed_at: :desc) }
  scope :by_type, ->(type) { where(maintenance_type: type) }
  scope :this_month, -> { where('performed_at >= ?', 1.month.ago) }
  scope :overdue, -> { where('next_service_date < ?', Date.today) }

  after_create :update_product_last_service_date

  def overdue?
    next_service_date.present? && next_service_date < Date.today
  end

  private

  def update_product_last_service_date
    product.update(last_service_date: performed_at.to_date)
  end
end
```

### Create a RESTful Controller
```ruby
# Generate controller
rails generate controller Api::V1::EquipmentMaintenanceLogs \
  index show create update destroy --skip-routes

# Controller: app/controllers/api/v1/equipment_maintenance_logs_controller.rb
class Api::V1::EquipmentMaintenanceLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_maintenance_log, only: [:show, :update, :destroy]
  before_action :authorize_user, only: [:update, :destroy]

  # GET /api/v1/equipment_maintenance_logs
  def index
    @logs = EquipmentMaintenanceLog
      .includes(:product, :performed_by)
      .page(params[:page])
      .per(params[:per_page] || 25)

    # Filter by product
    @logs = @logs.where(product_id: params[:product_id]) if params[:product_id]

    # Filter by type
    @logs = @logs.by_type(params[:maintenance_type]) if params[:maintenance_type]

    # Filter by date range
    if params[:start_date] && params[:end_date]
      @logs = @logs.where(performed_at: params[:start_date]..params[:end_date])
    end

    render json: {
      maintenance_logs: @logs.map { |log| serialize_log(log) },
      meta: pagination_meta(@logs)
    }
  end

  # GET /api/v1/equipment_maintenance_logs/:id
  def show
    render json: { maintenance_log: serialize_log(@log) }
  end

  # POST /api/v1/equipment_maintenance_logs
  def create
    @log = EquipmentMaintenanceLog.new(log_params)
    @log.performed_by = current_user

    if @log.save
      render json: { maintenance_log: serialize_log(@log) }, status: :created
    else
      render json: { errors: @log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/equipment_maintenance_logs/:id
  def update
    if @log.update(log_params)
      render json: { maintenance_log: serialize_log(@log) }
    else
      render json: { errors: @log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/equipment_maintenance_logs/:id
  def destroy
    @log.destroy
    head :no_content
  end

  private

  def set_maintenance_log
    @log = EquipmentMaintenanceLog.find(params[:id])
  end

  def authorize_user
    unless current_user.admin? || @log.performed_by == current_user
      render json: { error: 'Unauthorized' }, status: :forbidden
    end
  end

  def log_params
    params.require(:maintenance_log).permit(
      :product_id,
      :maintenance_type,
      :performed_at,
      :cost_cents,
      :cost_currency,
      :notes,
      :next_service_date
    )
  end

  def serialize_log(log)
    {
      id: log.id,
      product: {
        id: log.product_id,
        name: log.product.name
      },
      maintenance_type: log.maintenance_type,
      performed_by: {
        id: log.performed_by_id,
        name: log.performed_by.name
      },
      performed_at: log.performed_at,
      cost: log.cost&.format,
      notes: log.notes,
      next_service_date: log.next_service_date,
      overdue: log.overdue?,
      created_at: log.created_at,
      updated_at: log.updated_at
    }
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.prev_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end
end

# Add routes: config/routes.rb
namespace :api do
  namespace :v1 do
    resources :equipment_maintenance_logs, only: [:index, :show, :create, :update, :destroy]
  end
end
```

### Create a Service Object
```ruby
# app/services/booking_confirmation_service.rb
class BookingConfirmationService
  def initialize(booking)
    @booking = booking
    @errors = []
  end

  def call
    return failure('Booking not found') unless @booking

    ActiveRecord::Base.transaction do
      # 1. Verify availability
      unless verify_availability
        return failure('Items not available for selected dates')
      end

      # 2. Update booking status
      @booking.update!(status: :confirmed, confirmed_at: Time.current)

      # 3. Reserve inventory
      reserve_inventory

      # 4. Send confirmation email
      send_confirmation_email

      # 5. Create calendar events
      create_calendar_events

      # 6. Notify team
      notify_team

      success
    rescue => e
      failure("Confirmation failed: #{e.message}")
    end
  end

  private

  def verify_availability
    @booking.booking_line_items.all? do |item|
      if item.bookable_type == 'Product'
        available = item.bookable.available_quantity(
          @booking.start_date,
          @booking.end_date
        )
        available >= item.quantity
      elsif item.bookable_type == 'Kit'
        item.bookable.available?(@booking.start_date, @booking.end_date)
      end
    end
  end

  def reserve_inventory
    @booking.booking_line_items.each do |item|
      # Update available quantity or mark as reserved
      # Implementation depends on your inventory system
    end
  end

  def send_confirmation_email
    BookingMailer.confirmation(@booking).deliver_later
  end

  def create_calendar_events
    # Create Google Calendar events if integration exists
    CalendarEventCreatorJob.perform_later(@booking.id)
  end

  def notify_team
    # Notify staff via Slack/email about new confirmed booking
    TeamNotificationJob.perform_later(@booking.id, 'booking_confirmed')
  end

  def success
    OpenStruct.new(success?: true, booking: @booking, errors: [])
  end

  def failure(message)
    @errors << message
    OpenStruct.new(success?: false, booking: @booking, errors: @errors)
  end
end

# Usage in controller:
# result = BookingConfirmationService.new(@booking).call
# if result.success?
#   render json: { booking: serialize_booking(result.booking) }
# else
#   render json: { errors: result.errors }, status: :unprocessable_entity
# end
```

### Create a Background Job
```ruby
# Generate job
rails generate job CalculateMonthlyRevenue

# app/jobs/calculate_monthly_revenue_job.rb
class CalculateMonthlyRevenueJob < ApplicationJob
  queue_as :analytics

  retry_on StandardError, wait: 5.minutes, attempts: 3

  def perform(company_id, month, year)
    company = Company.find(company_id)

    ActsAsTenant.with_tenant(company) do
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      # Calculate revenue
      revenue = Booking.where(
        'created_at >= ? AND created_at <= ?',
        start_date,
        end_date
      ).where(status: [:paid, :completed])
       .sum(:grand_total_cents)

      # Calculate bookings count
      bookings_count = Booking.where(
        'created_at >= ? AND created_at <= ?',
        start_date,
        end_date
      ).where(status: [:paid, :completed]).count

      # Store metrics
      CompanyMetric.create!(
        company: company,
        metric_date: start_date,
        metric_type: 'monthly_revenue',
        value: revenue,
        metadata: {
          bookings_count: bookings_count,
          avg_booking_value: bookings_count > 0 ? revenue / bookings_count : 0
        }
      )

      # Send report to company admins
      company.users.where(role: :admin).each do |admin|
        RevenueReportMailer.monthly_report(admin, start_date, revenue).deliver_later
      end
    end
  end
end

# Schedule with sidekiq-cron or whenever gem
# Every 1st of month at 2am:
# CalculateMonthlyRevenueJob.perform_later(company.id, Date.today.prev_month.month, Date.today.prev_month.year)
```

### Optimize N+1 Queries
```ruby
# Before (N+1 query issue):
@bookings = Booking.all
@bookings.each do |booking|
  puts booking.client.name  # N queries
  puts booking.manager.name  # N queries
  booking.booking_line_items.each do |item|
    puts item.bookable.name  # N * M queries
  end
end

# After (optimized):
@bookings = Booking
  .includes(:client, :manager)
  .includes(booking_line_items: :bookable)
  .all

@bookings.each do |booking|
  puts booking.client.name  # No additional query
  puts booking.manager.name  # No additional query
  booking.booking_line_items.each do |item|
    puts item.bookable.name  # No additional query
  end
end

# Use bullet gem to detect N+1 queries:
# Add to Gemfile:
# gem 'bullet', group: 'development'

# config/environments/development.rb:
# config.after_initialize do
#   Bullet.enable = true
#   Bullet.alert = true
#   Bullet.rails_logger = true
# end
```

### Add Database Indexes
```ruby
# Generate migration
rails generate migration AddIndexesToImprovePerformance

# db/migrate/XXXXXX_add_indexes_to_improve_performance.rb
class AddIndexesToImprovePerformance < ActiveRecord::Migration[8.0]
  def change
    # Composite indexes for common queries
    add_index :bookings, [:company_id, :status, :start_date]
    add_index :bookings, [:company_id, :created_at]
    add_index :booking_line_items, [:bookable_type, :bookable_id, :booking_id]

    # Foreign key indexes
    add_index :products, :company_id
    add_index :clients, :company_id

    # Unique constraints
    add_index :companies, :subdomain, unique: true
    add_index :users, [:email, :company_id], unique: true

    # Partial indexes for common filters
    add_index :bookings, :start_date, where: "status IN ('confirmed', 'paid', 'in_progress')"
    add_index :products, :daily_price_cents, where: "active = true"
  end
end
```

### Implement Soft Deletes
```ruby
# Generate migration
rails generate migration AddDeletedAtToProducts deleted_at:datetime

# Migration
class AddDeletedAtToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :deleted_at, :datetime
    add_index :products, :deleted_at
  end
end

# Model with paranoia gem or custom implementation
class Product < ApplicationRecord
  # Using paranoia gem:
  # acts_as_paranoid

  # Or custom implementation:
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current, active: false)
  end

  def restore
    update(deleted_at: nil, active: true)
  end

  def deleted?
    deleted_at.present?
  end
end

# Override default scope to exclude soft-deleted
default_scope -> { where(deleted_at: nil) }

# Access all records including deleted
Product.unscoped.all
```

### Add Custom Validations
```ruby
class Booking < ApplicationRecord
  validate :end_date_after_start_date
  validate :dates_not_in_past, on: :create
  validate :availability_check, if: :will_save_change_to_start_date_or_end_date?
  validate :within_subscription_limits

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def dates_not_in_past
    if start_date.present? && start_date < Date.today
      errors.add(:start_date, "cannot be in the past")
    end
  end

  def availability_check
    booking_line_items.each do |item|
      available = item.bookable.available_quantity(start_date, end_date)
      if available < item.quantity
        errors.add(
          :base,
          "#{item.bookable.name} - only #{available} available (requested #{item.quantity})"
        )
      end
    end
  end

  def within_subscription_limits
    company = ActsAsTenant.current_tenant
    return unless company

    monthly_bookings = company.bookings.where(
      'created_at >= ?',
      1.month.ago
    ).count

    if monthly_bookings >= company.max_bookings_per_month
      errors.add(:base, "Monthly booking limit reached. Please upgrade your plan.")
    end
  end
end
```

## Testing

### Model Specs (RSpec)
```ruby
# spec/models/equipment_maintenance_log_spec.rb
require 'rails_helper'

RSpec.describe EquipmentMaintenanceLog, type: :model do
  let(:company) { create(:company) }
  let(:product) { create(:product, company: company) }
  let(:user) { create(:user, company: company) }

  subject do
    described_class.new(
      product: product,
      performed_by: user,
      performed_at: Time.current,
      maintenance_type: :routine_service,
      company: company
    )
  end

  describe 'associations' do
    it { should belong_to(:product) }
    it { should belong_to(:performed_by).class_name('User') }
    it { should belong_to(:company) }
  end

  describe 'validations' do
    it { should validate_presence_of(:product) }
    it { should validate_presence_of(:performed_by) }
    it { should validate_presence_of(:performed_at) }
    it { should validate_presence_of(:maintenance_type) }
  end

  describe 'scopes' do
    it 'returns recent logs first' do
      old_log = create(:maintenance_log, performed_at: 2.days.ago)
      new_log = create(:maintenance_log, performed_at: 1.day.ago)

      expect(EquipmentMaintenanceLog.recent.first).to eq(new_log)
    end
  end

  describe '#overdue?' do
    it 'returns true when next_service_date is in the past' do
      subject.next_service_date = 1.day.ago
      expect(subject.overdue?).to be true
    end

    it 'returns false when next_service_date is in the future' do
      subject.next_service_date = 1.day.from_now
      expect(subject.overdue?).to be false
    end
  end
end
```

### Controller Specs
```ruby
# spec/requests/api/v1/equipment_maintenance_logs_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::EquipmentMaintenanceLogs', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company: company) }
  let(:headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'GET /api/v1/equipment_maintenance_logs' do
    it 'returns a list of maintenance logs' do
      create_list(:maintenance_log, 3, company: company)

      get '/api/v1/equipment_maintenance_logs', headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['maintenance_logs'].size).to eq(3)
    end
  end

  describe 'POST /api/v1/equipment_maintenance_logs' do
    let(:product) { create(:product, company: company) }
    let(:valid_params) do
      {
        maintenance_log: {
          product_id: product.id,
          maintenance_type: 'routine_service',
          performed_at: Time.current,
          cost_cents: 5000,
          notes: 'Regular servicing'
        }
      }
    end

    it 'creates a new maintenance log' do
      expect {
        post '/api/v1/equipment_maintenance_logs',
          params: valid_params,
          headers: headers
      }.to change(EquipmentMaintenanceLog, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
```

## Performance Best Practices

1. **Use database indexes** for frequently queried columns
2. **Eager load associations** to prevent N+1 queries
3. **Use counter caches** for has_many relationships
4. **Implement pagination** for large datasets
5. **Use select** to fetch only needed columns
6. **Cache expensive queries** with Rails.cache
7. **Use background jobs** for slow operations
8. **Optimize database queries** with EXPLAIN ANALYZE

## Security Best Practices

1. **Always use strong parameters** in controllers
2. **Implement authorization** (use Pundit or CanCanCan)
3. **Sanitize user input** to prevent SQL injection
4. **Use encrypted credentials** for secrets
5. **Implement rate limiting** on API endpoints
6. **Add CSRF protection** for non-API requests
7. **Use HTTPS** in production
8. **Validate file uploads** and scan for malware

## Related Skills
- frontend-developer
- database-administrator
- devops-engineer
- qa-tester
- technical-architect
