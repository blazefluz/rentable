class Company < ApplicationRecord
  # Audit trail
  has_paper_trail

  # Associations
  has_many :users, dependent: :nullify
  has_many :products, dependent: :destroy
  has_many :kits, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :product_types, dependent: :destroy
  has_many :pricing_rules, dependent: :destroy
  has_many :tax_rates, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :product_bundles, dependent: :destroy
  has_many :product_collections, dependent: :destroy
  has_many :recurring_bookings, dependent: :destroy
  has_many :booking_templates, dependent: :destroy
  has_many :leads, dependent: :destroy
  has_many :asset_groups, dependent: :destroy
  has_many :maintenance_jobs, dependent: :destroy
  # has_one :subscription, dependent: :destroy  # Subscription model not yet created
  has_many_attached :branding_assets

  # Enums
  enum :status, {
    trial: 0,
    active: 1,
    suspended: 2,
    cancelled: 3,
    expired: 4
  }, prefix: true

  enum :subscription_tier, {
    free: 0,
    starter: 1,
    professional: 2,
    enterprise: 3
  }, prefix: true

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :subdomain, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: {
                          with: /\A[a-z0-9][a-z0-9\-]*[a-z0-9]\z/i,
                          message: "can only contain letters, numbers, and hyphens (not at start/end)"
                        },
                        length: { minimum: 3, maximum: 63 }
  validates :custom_domain, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :default_currency, inclusion: { in: %w[USD EUR GBP CAD AUD] }
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :business_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Reserved subdomains
  RESERVED_SUBDOMAINS = %w[
    www api app admin dashboard support help docs blog
    mail ftp ssh staging demo test development production
    assets cdn static media files uploads downloads
    secure ssl vpn proxy gateway portal login signup
    billing account settings profile status health metrics
  ].freeze

  validate :subdomain_not_reserved

  # Scopes
  scope :active, -> { where(active: true, deleted: false) }
  scope :trial, -> { where(status: :trial) }
  scope :subscribed, -> { where(status: :active) }
  scope :suspended, -> { where(status: :suspended) }
  scope :on_trial, -> { trial.where('trial_ends_at > ?', Time.current) }
  scope :trial_expired, -> { trial.where('trial_ends_at <= ?', Time.current) }
  scope :by_subdomain, ->(subdomain) { where('LOWER(subdomain) = ?', subdomain.to_s.downcase) }
  scope :by_domain, ->(domain) { where('LOWER(custom_domain) = ? OR LOWER(subdomain) = ?', domain.to_s.downcase, domain.to_s.downcase) }

  # Callbacks
  before_validation :normalize_subdomain
  before_validation :set_defaults, on: :create
  after_create :setup_default_data

  # ============================================================================
  # TENANT RESOLUTION
  # ============================================================================

  def self.current
    ActsAsTenant.current_tenant
  end

  def self.current=(company)
    ActsAsTenant.current_tenant = company
  end

  # Find company by subdomain or custom domain
  def self.find_by_domain(domain)
    # Remove www. prefix if present
    domain = domain.sub(/^www\./, '')

    # Try custom domain first, then subdomain
    find_by('LOWER(custom_domain) = ?', domain.downcase) ||
      find_by('LOWER(subdomain) = ?', domain.downcase)
  end

  # ============================================================================
  # TRIAL & SUBSCRIPTION MANAGEMENT
  # ============================================================================

  def on_trial?
    status_trial? && trial_ends_at.present? && trial_ends_at > Time.current
  end

  def trial_expired?
    status_trial? && trial_ends_at.present? && trial_ends_at <= Time.current
  end

  def trial_days_remaining
    return 0 unless on_trial?
    ((trial_ends_at - Time.current) / 1.day).ceil
  end

  def start_trial!(days: 14)
    update!(
      status: :trial,
      trial_ends_at: days.days.from_now,
      active: true
    )
  end

  def activate_subscription!(tier: :starter)
    update!(
      status: :active,
      subscription_tier: tier,
      subscription_started_at: Time.current,
      active: true
    )
  end

  def suspend!(reason: nil)
    update!(
      status: :suspended,
      active: false
    )
    settings[:suspension_reason] = reason if reason
    save
  end

  def cancel_subscription!
    update!(
      status: :cancelled,
      subscription_cancelled_at: Time.current,
      active: false
    )
  end

  # ============================================================================
  # FEATURE GATES
  # ============================================================================

  def feature_enabled?(feature_name)
    case feature_name.to_sym
    when :multi_location
      subscription_tier_professional? || subscription_tier_enterprise?
    when :advanced_analytics
      subscription_tier_professional? || subscription_tier_enterprise?
    when :api_access
      subscription_tier_professional? || subscription_tier_enterprise?
    when :white_label
      subscription_tier_enterprise?
    when :custom_domain
      subscription_tier_enterprise?
    when :priority_support
      subscription_tier_professional? || subscription_tier_enterprise?
    when :unlimited_users
      subscription_tier_enterprise?
    when :contracts
      subscription_tier_professional? || subscription_tier_enterprise?
    when :recurring_bookings
      subscription_tier_professional? || subscription_tier_enterprise?
    when :product_bundles
      subscription_tier_professional? || subscription_tier_enterprise?
    else
      true # All features enabled for free tier for now
    end
  end

  def max_users
    case subscription_tier
    when 'free' then 2
    when 'starter' then 10
    when 'professional' then 50
    when 'enterprise' then Float::INFINITY
    else 2
    end
  end

  def max_products
    case subscription_tier
    when 'free' then 50
    when 'starter' then 500
    when 'professional' then 5000
    when 'enterprise' then Float::INFINITY
    else 50
    end
  end

  def max_bookings_per_month
    case subscription_tier
    when 'free' then 20
    when 'starter' then 200
    when 'professional' then Float::INFINITY
    when 'enterprise' then Float::INFINITY
    else 20
    end
  end

  def can_add_user?
    users.active.count < max_users
  end

  def can_add_product?
    products.active.count < max_products
  end

  # ============================================================================
  # BRANDING & CUSTOMIZATION
  # ============================================================================

  def branding
    {
      logo: logo,
      primary_color: primary_color,
      secondary_color: secondary_color,
      company_name: name,
      business_email: business_email,
      business_phone: business_phone,
      timezone: timezone,
      currency: default_currency
    }
  end

  def update_branding!(attributes)
    update!(attributes.slice(:logo, :primary_color, :secondary_color))
  end

  def primary_domain
    custom_domain.presence || "#{subdomain}.rentable.com"
  end

  def full_url(path = '/')
    protocol = Rails.env.production? ? 'https' : 'http'
    "#{protocol}://#{primary_domain}#{path}"
  end

  # ============================================================================
  # SETTINGS MANAGEMENT
  # ============================================================================

  def setting(key)
    settings[key.to_s]
  end

  def set_setting(key, value)
    self.settings ||= {}
    self.settings[key.to_s] = value
    save
  end

  def update_settings!(new_settings)
    self.settings = settings.merge(new_settings.stringify_keys)
    save!
  end

  # ============================================================================
  # SOFT DELETE
  # ============================================================================

  def soft_delete!
    update!(
      deleted: true,
      deleted_at: Time.current,
      active: false,
      status: :cancelled
    )
  end

  def restore!
    update!(
      deleted: false,
      deleted_at: nil,
      active: true
    )
  end

  # ============================================================================
  # STATISTICS
  # ============================================================================

  def total_revenue(start_date = nil, end_date = nil)
    scope = bookings.where(status: [:completed, :paid])
    scope = scope.where('created_at >= ?', start_date) if start_date
    scope = scope.where('created_at <= ?', end_date) if end_date
    scope.sum(:total_price_cents)
  end

  def active_bookings_count
    bookings.active.confirmed_or_paid.count
  end

  def total_clients_count
    clients.active.count
  end

  def utilization_rate(start_date, end_date)
    # Calculate overall equipment utilization
    total_days = (end_date - start_date).to_i
    return 0 if total_days.zero?

    rented_days = bookings
      .where('start_date >= ? AND end_date <= ?', start_date, end_date)
      .where(status: [:confirmed, :paid, :completed])
      .sum('end_date - start_date')

    (rented_days.to_f / (total_days * products.active.count)) * 100
  end

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip.gsub(/[^a-z0-9\-]/, '-').gsub(/\-+/, '-').gsub(/^\-|\-$/, '')
  end

  def subdomain_not_reserved
    if subdomain.present? && RESERVED_SUBDOMAINS.include?(subdomain.downcase)
      errors.add(:subdomain, 'is reserved and cannot be used')
    end
  end

  def set_defaults
    self.status ||= :trial
    self.subscription_tier ||= :free
    self.trial_ends_at ||= 14.days.from_now
    self.active = true if active.nil?
    self.deleted = false if deleted.nil?
    self.timezone ||= 'UTC'
    self.default_currency ||= 'USD'
    self.primary_color ||= '#3B82F6'
    self.secondary_color ||= '#10B981'
    self.settings ||= {}
  end

  def setup_default_data
    # Create default admin user will be handled separately
    # Create default location, product types, etc.
    true
  end
end
