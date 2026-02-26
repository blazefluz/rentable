# app/models/booking.rb
class Booking < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  has_many :booking_line_items, dependent: :destroy
  has_many :products, through: :booking_line_items, source: :bookable, source_type: "Product"
  has_many :kits, through: :booking_line_items, source: :bookable, source_type: "Kit"
  has_many :payments, dependent: :destroy
  has_many :booking_comments, dependent: :destroy
  has_many :damage_reports, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many_attached :attachments

  belongs_to :client, optional: true
  belongs_to :manager, class_name: "User", optional: true
  belongs_to :venue_location, class_name: "Location", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  belongs_to :quote_approved_by, class_name: "User", optional: true
  belongs_to :recurring_booking, optional: true
  belongs_to :lead, optional: true
  belongs_to :default_tax_rate, class_name: "TaxRate", optional: true
  belongs_to :tax_override_by, class_name: "User", optional: true

  # Nested attributes
  accepts_nested_attributes_for :booking_line_items, allow_destroy: true

  # Monetize
  monetize :total_price_cents, as: :total_price, with_model_currency: :total_price_currency
  monetize :security_deposit_cents, as: :security_deposit, with_model_currency: :security_deposit_currency, allow_nil: true
  monetize :refund_amount_cents, as: :refund_amount, with_model_currency: :refund_amount_currency, allow_nil: true
  monetize :subtotal_cents, as: :subtotal, with_model_currency: :subtotal_currency, allow_nil: true
  monetize :tax_total_cents, as: :tax_total, with_model_currency: :tax_total_currency, allow_nil: true
  monetize :grand_total_cents, as: :grand_total, with_model_currency: :grand_total_currency, allow_nil: true
  monetize :tax_override_amount_cents, as: :tax_override_amount, with_model_currency: :tax_total_currency, allow_nil: true

  # Enums
  enum :status, {
    draft: 0,
    pending: 1,
    confirmed: 2,
    paid: 3,
    cancelled: 4,
    completed: 5
  }, prefix: true

  enum :security_deposit_status, {
    not_required: 0,
    pending_collection: 1,
    collected: 2,
    partially_refunded: 3,
    fully_refunded: 4,
    forfeited: 5
  }, prefix: true

  enum :cancellation_policy, {
    flexible: 0,        # Full refund 7+ days before start
    moderate: 1,        # Full refund 14+ days, 50% refund 7+ days
    strict: 2,          # Full refund 30+ days, 50% refund 14+ days, no refund < 14 days
    no_refund: 3,       # No refunds allowed
    custom: 4           # Use custom cancellation_deadline_hours and cancellation_fee_percentage
  }, prefix: true

  enum :refund_status, {
    not_applicable: 0,
    pending: 1,
    processing: 2,
    completed: 3,
    failed: 4
  }, prefix: true

  enum :quote_status, {
    quote_draft: 0,
    quote_sent: 1,
    quote_viewed: 2,
    quote_approved: 3,
    quote_declined: 4,
    quote_expired: 5
  }, prefix: true

  # Validations
  validates :start_date, :end_date, :customer_name, :customer_email, presence: true
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :total_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price_currency, inclusion: { in: %w[USD EUR GBP] }
  validate :end_date_after_start_date
  validate :availability_on_create, on: :create

  # Callbacks
  before_validation :generate_reference_number, on: :create
  before_validation :calculate_total_price

  # Scopes
  scope :active, -> { where.not(status: [:cancelled]).where(deleted: false) }
  scope :confirmed_or_paid, -> { where(status: [:confirmed, :paid, :completed]) }
  scope :overlapping, ->(start_date, end_date) {
    where("start_date < ? AND end_date > ?", end_date, start_date)
  }
  scope :archived_records, -> { where(archived: true) }
  scope :not_archived, -> { where(archived: false) }
  scope :not_deleted, -> { where(deleted: false) }
  scope :quotes, -> { where(status: :draft).where.not(quote_number: nil) }
  scope :active_quotes, -> { quotes.where(quote_status: [:quote_draft, :quote_sent, :quote_viewed]) }
  scope :expired_quotes, -> { quotes.where('quote_expires_at < ?', Time.current) }
  scope :pending_quotes, -> { quotes.where(quote_status: [:quote_sent, :quote_viewed]) }

  # Calculate number of rental days
  def rental_days
    return 0 if start_date.nil? || end_date.nil?
    ((end_date.to_date - start_date.to_date).to_i + 1).clamp(1..)
  end

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end

  # Archive
  def archive!
    update(archived: true)
  end

  def unarchive!
    update(archived: false)
  end

  # Get total payments received
  def total_payments_received
    payments.where(payment_type: :payment_received, deleted: false).sum(:amount_cents)
  end

  # Get balance due
  def balance_due
    total_price_cents - total_payments_received
  end

  # Check if fully paid
  def fully_paid?
    balance_due <= 0
  end

  # Damage and security deposit methods
  def has_damage_reports?
    damage_reports.any?
  end

  def unresolved_damage_reports
    damage_reports.unresolved
  end

  def total_damage_cost
    damage_reports.sum(:repair_cost_cents)
  end

  def collect_security_deposit!
    return false unless security_deposit_cents.present?
    update(security_deposit_status: :collected)
  end

  def refund_security_deposit!(partial_amount: nil)
    return false unless security_deposit_status_collected?

    if partial_amount
      update(security_deposit_status: :partially_refunded, security_deposit_refunded_at: Time.current)
    else
      update(security_deposit_status: :fully_refunded, security_deposit_refunded_at: Time.current)
    end
  end

  def forfeit_security_deposit!
    update(security_deposit_status: :forfeited, security_deposit_refunded_at: Time.current)
  end

  # Quote/Estimate Workflow Methods

  # Convert booking to a quote
  def convert_to_quote!(valid_days: 30, terms: nil)
    return false if quote_number.present? # Already a quote

    self.quote_number = generate_quote_number
    self.quote_valid_days = valid_days
    self.quote_expires_at = valid_days.days.from_now
    self.quote_status = :quote_draft
    self.quote_terms = terms
    self.status = :draft
    save!
  end

  # Send quote to customer
  def send_quote!
    return false unless quote_number.present?
    return false if quote_status_quote_expired?

    update!(
      quote_status: :quote_sent,
      quote_sent_at: Time.current
    )

    # Here you would trigger quote email
    # QuoteMailer.quote_email(self).deliver_later
  end

  # Mark quote as viewed (when customer opens it)
  def mark_quote_viewed!
    return false unless quote_status_quote_sent?

    update!(
      quote_status: :quote_viewed,
      quote_viewed_at: Time.current
    )
  end

  # Approve quote and convert to booking
  def approve_quote!(approved_by: nil)
    return false unless quote_number.present?
    return false if quote_expired?

    update!(
      quote_status: :quote_approved,
      quote_approved_at: Time.current,
      quote_approved_by: approved_by,
      status: :confirmed, # Convert from draft to confirmed
      converted_from_quote: true
    )
  end

  # Decline quote
  def decline_quote!(reason: nil)
    return false unless quote_number.present?

    update!(
      quote_status: :quote_declined,
      quote_declined_at: Time.current,
      quote_decline_reason: reason
    )
  end

  # Check if quote is expired
  def quote_expired?
    quote_expires_at.present? && quote_expires_at < Time.current
  end

  # Mark expired quotes (call this in a daily job)
  def self.expire_old_quotes!
    expired_quotes.where.not(quote_status: :quote_expired).find_each do |booking|
      booking.update!(quote_status: :quote_expired)
    end
  end

  # Duplicate quote (for creating revised quote)
  def duplicate_quote(changes = {})
    new_booking = self.dup
    new_booking.quote_number = nil # Will generate new one
    new_booking.quote_status = :quote_draft
    new_booking.quote_sent_at = nil
    new_booking.quote_viewed_at = nil
    new_booking.quote_approved_at = nil
    new_booking.quote_declined_at = nil
    new_booking.quote_expires_at = (changes[:valid_days] || 30).days.from_now
    new_booking.reference_number = nil # Will generate new one
    new_booking.assign_attributes(changes)

    # Duplicate line items
    booking_line_items.each do |item|
      new_item = item.dup
      new_booking.booking_line_items << new_item
    end

    new_booking.save!
    new_booking.convert_to_quote!
    new_booking
  end

  # Get days until quote expires
  def days_until_expiry
    return nil unless quote_expires_at.present?
    ((quote_expires_at - Time.current) / 1.day).ceil
  end

  # Check if quote needs attention (expiring soon)
  def quote_expiring_soon?(days = 3)
    return false unless quote_expires_at.present?
    !quote_expired? && days_until_expiry <= days
  end

  # Booking Template Methods

  # Save booking as template
  def save_as_template(name:, **options)
    BookingTemplate.create_from_booking(self, options.merge(name: name))
  end

  # Check if booking was created from template
  def from_template?
    # Could add a booking_template_id field if needed
    # For now, check if there's a template with matching data
    false
  end

  # Cancellation policy methods
  def can_cancel?
    return false if status_cancelled? || status_completed?
    true
  end

  def hours_until_start
    return 0 if start_date.blank?
    ((start_date - Time.current) / 1.hour).to_i
  end

  def calculate_cancellation_refund
    return { refund_cents: 0, fee_cents: total_price_cents, refund_percentage: 0 } if cancellation_policy_no_refund?

    hours_before = hours_until_start
    refund_percentage = determine_refund_percentage(hours_before)

    refund_cents = (total_price_cents * refund_percentage / 100.0).round
    fee_cents = total_price_cents - refund_cents

    {
      refund_cents: refund_cents,
      fee_cents: fee_cents,
      refund_percentage: refund_percentage,
      hours_before_start: hours_before
    }
  end

  def cancel_booking!(user: nil, reason: nil)
    return false unless can_cancel?

    refund_info = calculate_cancellation_refund

    transaction do
      update!(
        status: :cancelled,
        cancelled_at: Time.current,
        cancelled_by: user,
        cancellation_reason: reason,
        refund_amount_cents: refund_info[:refund_cents],
        refund_amount_currency: total_price_currency,
        refund_status: refund_info[:refund_cents] > 0 ? :pending : :not_applicable
      )

      # Release product instances back to available
      booking_line_items.each do |line_item|
        line_item.product_instances.each do |instance|
          instance.mark_as_available if instance.respond_to?(:mark_as_available)
        end
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def process_refund!
    return false unless status_cancelled? && refund_status_pending?

    update(
      refund_status: :processing,
      refund_processed_at: Time.current
    )

    # This would integrate with payment processor
    # For now, mark as completed
    update(refund_status: :completed)
  end

  def cancellation_deadline
    return nil if cancellation_policy_no_refund?
    return start_date - cancellation_deadline_hours.hours if cancellation_policy_custom?

    case cancellation_policy.to_sym
    when :flexible
      start_date - 7.days
    when :moderate
      start_date - 14.days
    when :strict
      start_date - 30.days
    else
      nil
    end
  end

  def past_cancellation_deadline?
    return true if cancellation_policy_no_refund?
    deadline = cancellation_deadline
    return false if deadline.nil?
    Time.current > deadline
  end

  def refund_allowed?
    !cancellation_policy_no_refund? && !past_cancellation_deadline?
  end

  # ============================================================================
  # TAX CALCULATIONS (Public methods)
  # ============================================================================

  def calculate_total_price
    return unless booking_line_items.any?

    currency = booking_line_items.first&.price_currency || "USD"

    # Calculate subtotal (before tax)
    self.subtotal_cents = booking_line_items.sum do |item|
      item.line_total.cents
    end
    self.subtotal_currency = currency

    # Calculate taxes
    calculate_taxes

    # Grand total = subtotal + tax
    self.grand_total_cents = subtotal_cents.to_i + tax_total_cents.to_i
    self.grand_total_currency = currency

    # For backward compatibility, set total_price to grand_total
    self.total_price_cents = grand_total_cents
    self.total_price_currency = currency
  end

  def calculate_taxes
    return unless booking_line_items.any?

    currency = booking_line_items.first&.price_currency || "USD"

    # Check if tax override is applied
    if tax_override?
      self.tax_total_cents = tax_override_amount_cents.to_i
      self.tax_total_currency = currency
      return
    end

    # Check if tax exempt
    if tax_exempt?
      self.tax_total_cents = 0
      self.tax_total_currency = currency
      return
    end

    # Calculate tax based on line items
    # First, calculate tax per line item
    booking_line_items.each do |item|
      item.calculate_tax
    end

    # Sum up all line item taxes
    self.tax_total_cents = booking_line_items.sum do |item|
      item.tax_amount_cents.to_i
    end
    self.tax_total_currency = currency
  end

  # Get applicable tax rates for this booking's location
  def applicable_tax_rates
    return [] unless venue_location

    TaxRate.for_location(
      country: venue_location.country || 'US',
      state: venue_location.state,
      city: venue_location.city,
      zip: venue_location.postal_code
    )
  end

  # Mark booking as tax exempt
  def mark_tax_exempt!(reason:, certificate: nil)
    update!(
      tax_exempt: true,
      tax_exempt_reason: reason,
      tax_exempt_certificate: certificate
    )
    calculate_total_price
  end

  # Override tax amount manually
  def override_tax!(amount:, reason:, user:)
    update!(
      tax_override: true,
      tax_override_amount_cents: amount.cents,
      tax_override_reason: reason,
      tax_override_by: user
    )
    calculate_total_price
  end

  # Check if reverse charge VAT applies (EU B2B)
  def apply_reverse_charge?
    return false unless venue_location&.country.present?
    return false unless client&.business_entities&.any?

    # Only for EU/UK VAT
    return false unless venue_location.country.in?(['GB', 'DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT', 'SE', 'DK', 'FI', 'IE', 'PT', 'GR', 'PL', 'CZ', 'HU', 'RO', 'BG', 'HR', 'SK', 'SI', 'LT', 'LV', 'EE', 'CY', 'MT', 'LU'])

    # Check if client has valid VAT number
    client_vat = client.business_entities.first&.tax_id
    return false unless client_vat.present?

    # Extract country code from VAT number (first 2 letters)
    client_country = client_vat[0..1]

    # Reverse charge applies if different EU countries
    client_country != venue_location.country
  end

  # Tax breakdown for display/reporting
  def tax_breakdown
    {
      subtotal: subtotal,
      tax_total: tax_total,
      grand_total: grand_total,
      tax_exempt: tax_exempt?,
      tax_override: tax_override?,
      reverse_charge: reverse_charge_applied?,
      line_items: booking_line_items.map do |item|
        {
          bookable: item.bookable&.name,
          line_total: item.line_total,
          tax_amount: item.tax_amount,
          tax_rate: item.tax_rate&.display_name
        }
      end
    }
  end

  private

  def determine_refund_percentage(hours_before)
    return cancellation_fee_percentage if cancellation_policy_custom?

    case cancellation_policy.to_sym
    when :flexible
      # Full refund if 7+ days (168 hours), otherwise no refund
      hours_before >= 168 ? 100 : 0
    when :moderate
      # Full refund if 14+ days (336 hours), 50% if 7+ days (168 hours)
      if hours_before >= 336
        100
      elsif hours_before >= 168
        50
      else
        0
      end
    when :strict
      # Full refund if 30+ days (720 hours), 50% if 14+ days (336 hours)
      if hours_before >= 720
        100
      elsif hours_before >= 336
        50
      else
        0
      end
    when :no_refund
      0
    else
      0
    end
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def generate_reference_number
    self.reference_number ||= "BK#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
  end

  def generate_quote_number
    "QT#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
  end

  def availability_on_create
    return if status_cancelled? || status_draft?

    booking_line_items.each do |line_item|
      bookable = line_item.bookable
      next unless bookable

      unless bookable.available?(start_date, end_date, line_item.quantity)
        errors.add(:base, "#{bookable.name} is not available for the selected dates")
      end
    end
  end
end
