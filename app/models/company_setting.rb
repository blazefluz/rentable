# app/models/company_setting.rb
# Configurable business rules and settings per company
# Replaces hardcoded values for late fees, cancellation windows, etc.
class CompanySetting < ApplicationRecord
  # Multi-tenancy
  belongs_to :company

  # Enums
  enum :setting_type, {
    string_type: 0,
    integer_type: 1,
    decimal_type: 2,
    boolean_type: 3,
    json_type: 4,
    money_type: 5,
    duration_type: 6
  }

  # Validations
  validates :setting_key, presence: true, uniqueness: { scope: :company_id }
  validates :setting_type, presence: true
  validates :category, presence: true

  # Scopes
  scope :editable, -> { where(editable: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Class methods to get/set settings with type casting
  class << self
    def get(key, company: nil)
      company ||= ActsAsTenant.current_tenant
      setting = find_by(company: company, setting_key: key)
      return nil unless setting

      cast_value(setting.setting_value, setting.setting_type)
    end

    def set(key, value, company: nil)
      company ||= ActsAsTenant.current_tenant
      setting = find_or_initialize_by(company: company, setting_key: key)
      setting.setting_value = value
      setting.save!
    end

    # Get setting with fallback to default
    def get_or_default(key, company: nil)
      company ||= ActsAsTenant.current_tenant
      setting = find_by(company: company, setting_key: key)
      return cast_value(setting.default_value, setting.setting_type) unless setting&.setting_value.present?

      cast_value(setting.setting_value, setting.setting_type)
    end

    private

    def cast_value(value, type)
      return value if value.nil?

      case type.to_s
      when 'integer_type'
        value.to_i
      when 'decimal_type'
        BigDecimal(value.to_s)
      when 'boolean_type'
        ActiveModel::Type::Boolean.new.cast(value)
      when 'money_type'
        Money.new(value['cents'], value['currency']) if value.is_a?(Hash)
      when 'json_type'
        value
      else
        value.to_s
      end
    end
  end

  # Instance methods
  def value
    self.class.send(:cast_value, setting_value, setting_type)
  end

  def default
    self.class.send(:cast_value, default_value, setting_type)
  end

  # Seed default settings for a company
  def self.seed_defaults(company)
    default_settings.each do |key, config|
      create_with(
        setting_type: config[:type],
        category: config[:category],
        description: config[:description],
        default_value: config[:default],
        setting_value: config[:default],
        editable: true
      ).find_or_create_by!(company: company, setting_key: key.to_s)
    end
  end

  def self.default_settings
    {
      late_fee_daily_rate: {
        type: :money_type,
        category: 'fees',
        description: 'Daily late fee charged for overdue returns',
        default: { 'cents' => 5000, 'currency' => 'USD' }
      },
      late_fee_grace_period_hours: {
        type: :integer_type,
        category: 'fees',
        description: 'Grace period before late fees apply (in hours)',
        default: 24
      },
      cancellation_window_hours: {
        type: :integer_type,
        category: 'cancellation',
        description: 'Hours before start date when cancellations are allowed',
        default: 48
      },
      cancellation_fee_percentage: {
        type: :decimal_type,
        category: 'cancellation',
        description: 'Percentage fee for cancellations (0-100)',
        default: 25.0
      },
      minimum_booking_hours: {
        type: :integer_type,
        category: 'booking',
        description: 'Minimum booking duration in hours',
        default: 24
      },
      maximum_booking_days: {
        type: :integer_type,
        category: 'booking',
        description: 'Maximum booking duration in days (0 = unlimited)',
        default: 0
      },
      require_security_deposit: {
        type: :boolean_type,
        category: 'payment',
        description: 'Require security deposit for all bookings',
        default: false
      },
      low_stock_threshold: {
        type: :integer_type,
        category: 'inventory',
        description: 'Notify when stock falls below this number',
        default: 2
      },
      maintenance_interval_days: {
        type: :integer_type,
        category: 'maintenance',
        description: 'Default maintenance interval in days',
        default: 90
      }
    }
  end
end
