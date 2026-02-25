# app/models/product.rb
class Product < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  has_many :kit_items, dependent: :destroy
  has_many :kits, through: :kit_items
  has_many :booking_line_items, as: :bookable
  has_many :bookings, through: :booking_line_items
  has_many :maintenance_jobs, dependent: :destroy
  has_many :asset_assignments, dependent: :destroy
  has_many :asset_logs, dependent: :destroy
  has_many :product_asset_flags, dependent: :destroy
  has_many :asset_flags, through: :product_asset_flags
  has_many :asset_group_products, dependent: :destroy
  has_many :asset_groups, through: :asset_group_products
  has_many_attached :images
  has_many :insurance_certificates, dependent: :destroy
  has_many :pricing_rules, dependent: :destroy
  has_many :product_instances, dependent: :destroy
  has_many :product_metrics, dependent: :destroy
  has_many :product_accessories, dependent: :destroy
  has_many :accessories, through: :product_accessories, source: :accessory
  has_many :parent_product_accessories, class_name: "ProductAccessory", foreign_key: :accessory_id, dependent: :destroy
  has_many :parent_products, through: :parent_product_accessories, source: :product
  has_many :product_bundle_items, dependent: :destroy
  has_many :product_bundles, through: :product_bundle_items

  belongs_to :product_type, optional: true
  belongs_to :storage_location, class_name: "Location", optional: true

  # Monetize
  monetize :daily_price_cents, as: :daily_price, with_model_currency: :daily_price_currency
  monetize :weekly_price_cents, as: :weekly_price, with_model_currency: :weekly_price_currency
  monetize :weekend_price_cents, as: :weekend_price, with_model_currency: :weekend_price_currency, allow_nil: true
  monetize :value_cents, as: :value, currency: :daily_price_currency
  monetize :purchase_price_cents, as: :purchase_price, with_model_currency: :purchase_price_currency, allow_nil: true
  monetize :current_value_cents, as: :current_value, with_model_currency: :current_value_currency, allow_nil: true
  monetize :replacement_cost_cents, as: :replacement_cost, with_model_currency: :replacement_cost_currency, allow_nil: true
  monetize :damage_waiver_price_cents, as: :damage_waiver_price, with_model_currency: :damage_waiver_price_currency, allow_nil: true
  monetize :late_fee_cents, as: :late_fee, with_model_currency: :late_fee_currency, allow_nil: true

  # Enums
  enum :condition, {
    new_condition: 0,
    excellent: 1,
    good: 2,
    fair: 3,
    needs_repair: 4,
    retired: 5
  }, prefix: true

  enum :late_fee_type, {
    per_day: 0,
    per_hour: 1,
    flat_fee: 2
  }, prefix: true

  enum :workflow_state, {
    available: 0,
    on_rent: 1,
    maintenance: 2,
    out_of_service: 3,
    reserved: 4,
    in_transit: 5,
    retired_state: 6
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :daily_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :barcode, uniqueness: true, allow_blank: true
  validates :asset_tag, uniqueness: true, allow_blank: true
  validates :daily_price_currency, inclusion: { in: %w[USD EUR GBP] }
  validates :weekly_price_currency, inclusion: { in: %w[USD EUR GBP] }

  # Scopes
  scope :active, -> { where(active: true, archived: false, deleted: false) }
  scope :archived, -> { where(archived: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search, ->(query) {
    if query.present?
      where("name ILIKE ? OR description ILIKE ? OR model_number ILIKE ? OR ? = ANY(tags)",
            "%#{query}%", "%#{query}%", "%#{query}%", query)
    end
  }
  scope :search_advanced, ->(query) {
    if query.present?
      where("name ILIKE ? OR description ILIKE ? OR model_number ILIKE ? OR ? = ANY(tags) OR specifications::text ILIKE ?",
            "%#{query}%", "%#{query}%", "%#{query}%", query, "%#{query}%")
    end
  }
  scope :by_product_type, ->(type_id) { where(product_type_id: type_id) if type_id.present? }
  scope :public_visible, -> { where(show_public: true) }
  scope :rentable, -> { where.not(condition: [:needs_repair, :retired]) }
  scope :needs_attention, -> { where(condition: [:needs_repair, :retired]) }
  scope :available_for_rent, -> { where(workflow_state: :available, active: true, archived: false, deleted: false) }
  scope :currently_rented, -> { where(workflow_state: :on_rent) }
  scope :in_maintenance_mode, -> { where(workflow_state: :maintenance).or(where(in_maintenance: true)) }
  scope :in_transit_mode, -> { where(workflow_state: :in_transit).or(where(in_transit: true)) }
  scope :with_tag, ->(tag) { where("? = ANY(tags)", tag) if tag.present? }
  scope :with_any_tags, ->(tags) { where("tags && ARRAY[?]::varchar[]", tags) if tags.present? }
  scope :by_model_number, ->(model) { where(model_number: model) if model.present? }
  scope :featured, -> { where(featured: true) }
  scope :popular, -> { where("popularity_score > ?", 0).order(popularity_score: :desc) }
  scope :by_specification, ->(key, value) { where("specifications->? = ?", key, value.to_json) if key.present? && value.present? }

  # Check if product is available for given date range and quantity
  def available?(start_date, end_date, requested_qty = 1)
    # If using instance tracking, check individual instances
    if uses_instance_tracking?
      available_instances_count(start_date, end_date) >= requested_qty
    else
      # Fall back to quantity-based availability
      AvailabilityChecker.new(self, start_date, end_date, requested_qty).available?
    end
  end

  # Get available quantity for date range
  def available_quantity(start_date, end_date)
    if uses_instance_tracking?
      available_instances_count(start_date, end_date)
    else
      AvailabilityChecker.new(self, start_date, end_date).available_quantity
    end
  end

  # Check if this product uses instance-level tracking
  def uses_instance_tracking?
    product_instances.any?
  end

  # Get count of available instances for a date range
  def available_instances_count(start_date, end_date)
    product_instances.available_instances.count
    # TODO: Filter by booking conflicts
  end

  # Get available instances for booking
  def available_instances_for_booking(start_date, end_date, quantity = 1)
    return [] unless uses_instance_tracking?

    # Get instances not booked during the period
    booked_instance_ids = BookingLineItem
      .joins(:booking, :product_instances)
      .where(bookable: self)
      .where("bookings.start_date <= ? AND bookings.end_date >= ?", end_date, start_date)
      .where.not(bookings: { status: Booking.statuses[:cancelled] })
      .pluck("product_instances.id")
      .uniq

    product_instances.available_instances
      .where.not(id: booked_instance_ids)
      .limit(quantity)
  end

  # Calculate depreciation based on purchase date and depreciation rate
  def calculate_depreciation
    return unless purchase_date.present? && purchase_price_cents.present? && depreciation_rate.present?

    years_old = (Date.today - purchase_date).to_f / 365.25
    depreciation_factor = (1 - depreciation_rate / 100.0) ** years_old

    self.current_value_cents = (purchase_price_cents * depreciation_factor).round
    self.current_value_currency = purchase_price_currency
    self.last_depreciation_date = Date.today
  end

  # Check if insurance is expired
  def insurance_expired?
    return false unless insurance_required? && insurance_expiry.present?
    insurance_expiry < Date.today
  end

  # Check if any insurance certificate is valid
  def has_valid_insurance?
    insurance_certificates.exists?(['end_date >= ? AND deleted = ?', Date.today, false])
  end

  # Check if product is in rentable condition
  def rentable?
    !condition_needs_repair? && !condition_retired?
  end

  # Update condition and log it
  def update_condition(new_condition, notes = nil)
    self.condition = new_condition
    self.condition_notes = notes if notes.present?
    self.last_condition_check = Date.today
    save
  end

  # Calculate rental price for a given date range
  def calculate_rental_price(start_date, end_date, quantity = 1)
    rental_days = (end_date.to_date - start_date.to_date).to_i + 1

    # Check minimum rental days
    return nil if minimum_rental_days.present? && rental_days < minimum_rental_days

    # Get applicable pricing rules
    applicable_rules = pricing_rules.active.by_priority

    base_price = calculate_base_price(rental_days, start_date, end_date)

    # Apply pricing rules in priority order
    applicable_rules.each do |rule|
      if rule.applies_to?(start_date, end_date, rental_days)
        base_price = rule.calculate_price(base_price, rental_days)
        break if rule.price_override_cents.present? # Stop if override price
      end
    end

    (base_price * quantity).round(2)
  end

  private

  def calculate_base_price(rental_days, start_date, end_date)
    # Weekly pricing if available and rental is 7+ days
    if weekly_price_cents.present? && rental_days >= 7
      weeks = rental_days / 7
      remaining_days = rental_days % 7
      return (weeks * weekly_price_cents) + (remaining_days * daily_price_cents)
    end

    # Weekend pricing if applicable
    if weekend_price_cents.present?
      weekend_days = count_weekend_days(start_date, end_date)
      weekday_days = rental_days - weekend_days
      return (weekend_days * weekend_price_cents) + (weekday_days * daily_price_cents)
    end

    # Default daily pricing
    rental_days * daily_price_cents
  end

  def count_weekend_days(start_date, end_date)
    (start_date..end_date).count { |date| date.saturday? || date.sunday? }
  end

  public

  # Workflow state management methods
  def mark_as_rented
    update(workflow_state: :on_rent)
  end

  def mark_as_available
    update(workflow_state: :available, reserved_until: nil)
  end

  def mark_for_maintenance(notes = nil)
    update(workflow_state: :maintenance, in_maintenance: true, condition_notes: notes)
  end

  def complete_maintenance
    update(workflow_state: :available, in_maintenance: false)
  end

  def mark_as_out_of_service(reason = nil)
    update(workflow_state: :out_of_service, out_of_service: true, condition_notes: reason)
  end

  def return_to_service
    update(workflow_state: :available, out_of_service: false)
  end

  def reserve_until(datetime, notes = nil)
    update(workflow_state: :reserved, reserved_until: datetime, condition_notes: notes)
  end

  def start_transit(notes = nil)
    update(workflow_state: :in_transit, in_transit: true, transit_notes: notes)
  end

  def end_transit
    update(workflow_state: :available, in_transit: false, transit_notes: nil)
  end

  def currently_available?
    workflow_state_available? && !in_maintenance? && !out_of_service? && !in_transit? &&
      (reserved_until.blank? || reserved_until < Time.current)
  end

  # Utilization metrics
  def calculate_metrics(date = Date.today)
    ProductMetric.calculate_for_product(self, date)
  end

  def utilization_rate(start_date, end_date)
    ProductMetric.average_utilization(self, start_date, end_date)
  end

  def total_revenue(start_date, end_date)
    ProductMetric.total_revenue(self, start_date, end_date)
  end

  def revenue_per_day(start_date, end_date)
    total_days = (end_date - start_date).to_i + 1
    return 0 if total_days.zero?
    total_revenue(start_date, end_date) / total_days.to_f
  end

  # Search and discovery methods
  def add_tag(tag)
    self.tags ||= []
    self.tags << tag unless self.tags.include?(tag)
    save
  end

  def remove_tag(tag)
    self.tags ||= []
    self.tags.delete(tag)
    save
  end

  def increment_popularity
    self.popularity_score ||= 0
    increment!(:popularity_score)
  end

  def set_specification(key, value)
    self.specifications ||= {}
    self.specifications[key] = value
    save
  end

  # Accessory methods
  def required_accessories
    product_accessories.required_accessories.includes(:accessory).map(&:accessory)
  end

  def suggested_accessories
    product_accessories.optional_accessories.includes(:accessory).map(&:accessory)
  end

  def bundled_accessories
    product_accessories.bundled_accessories.includes(:accessory).map(&:accessory)
  end

  def add_accessory(accessory_product, type: :suggested, required: false, quantity: 1)
    product_accessories.create!(
      accessory: accessory_product,
      accessory_type: type,
      required: required,
      default_quantity: quantity
    )
  end

  # Bundling methods
  def enforced_bundles
    product_bundles.active.enforced
  end

  def suggested_bundles
    product_bundles.active.where(bundle_type: [:suggested_bundle, :cross_sell, :upsell])
  end

  def must_rent_with
    # Get all products that MUST be rented together with this one
    enforced_bundles.bundle_type_must_rent_together.flat_map do |bundle|
      bundle.required_products.reject { |p| p.id == id }
    end.uniq
  end

  def cross_sell_products
    # Products suggested as cross-sells
    product_bundles.active.bundle_type_cross_sell.flat_map do |bundle|
      bundle.products.reject { |p| p.id == id }
    end.uniq
  end

  def upsell_products
    # Products suggested as upsells/upgrades
    product_bundles.active.bundle_type_upsell.flat_map do |bundle|
      bundle.products.reject { |p| p.id == id }
    end.uniq
  end

  def frequently_rented_with
    # Products frequently rented together
    product_bundles.active.bundle_type_frequently_together.flat_map do |bundle|
      bundle.products.reject { |p| p.id == id }
    end.uniq
  end

  # Check if this product can be rented without its required bundle items
  def can_rent_standalone?
    enforced_bundles.empty?
  end

  # Get missing required products for a given set of product IDs
  def missing_bundle_requirements(product_ids)
    enforced_bundles.flat_map do |bundle|
      bundle.missing_required_products(product_ids + [id])
    end.uniq
  end

  # Calculate bundle discounts that apply to this product
  def applicable_bundle_discounts(booking_line_items)
    discounts = []

    product_bundles.active.where.not(discount_percentage: nil).each do |bundle|
      if bundle.satisfied_by_booking?(booking_line_items.first.booking)
        discount = bundle.calculate_bundle_discount(booking_line_items)
        discounts << { bundle: bundle, discount_cents: discount }
      end
    end

    discounts
  end
end
