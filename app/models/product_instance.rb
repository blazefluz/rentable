class ProductInstance < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :product
  belongs_to :current_location, class_name: "Location", optional: true
  has_many :booking_line_item_instances, dependent: :destroy
  has_many :booking_line_items, through: :booking_line_item_instances
  has_many :bookings, through: :booking_line_items
  has_many :location_histories, as: :trackable, dependent: :destroy

  # Callbacks
  after_update :track_location_change, if: :saved_change_to_current_location_id?

  # Enums - mirror product condition states
  enum :condition, {
    new_condition: 0,
    excellent: 1,
    good: 2,
    fair: 3,
    needs_repair: 4,
    retired: 5
  }, prefix: true

  enum :status, {
    available: 0,
    on_rent: 1,
    in_maintenance: 2,
    out_of_service: 3,
    reserved: 4,
    in_transit: 5,
    retired_status: 6
  }, prefix: true

  # Monetize
  monetize :purchase_price_cents, as: :purchase_price, with_model_currency: :purchase_price_currency, allow_nil: true

  # Validations
  validates :serial_number, uniqueness: true, allow_blank: true
  validates :asset_tag, uniqueness: true, allow_blank: true

  # Scopes
  scope :active, -> { where(deleted: false) }
  scope :available_instances, -> { where(status: :available, deleted: false) }
  scope :on_rent_instances, -> { where(status: :on_rent, deleted: false) }
  scope :needs_attention, -> { where(condition: [:needs_repair, :retired], deleted: false) }

  # Check if instance is rentable
  def rentable?
    status_available? && !condition_needs_repair? && !condition_retired?
  end

  # Update status
  def mark_as_rented
    update(status: :on_rent)
  end

  def mark_as_available
    update(status: :available)
  end

  def mark_for_maintenance(notes = nil)
    update(status: :in_maintenance, notes: notes)
  end

  def complete_maintenance
    update(status: :available)
  end

  # Calculate current value with depreciation
  def current_value
    return nil unless purchase_price_cents.present? && product.depreciation_rate.present? && purchase_date.present?

    years_old = (Date.today - purchase_date).to_f / 365.25
    depreciation_factor = (1 - product.depreciation_rate / 100.0) ** years_old

    (purchase_price_cents * depreciation_factor).round
  end

  # Location tracking methods
  def move_to_location(new_location, moved_by: nil, notes: nil)
    old_location = current_location
    self.current_location = new_location
    if save
      LocationHistory.track_movement(self, new_location, moved_by: moved_by, notes: notes)
      true
    else
      false
    end
  end

  def location_history_trail
    location_histories.recent.includes(:location, :previous_location, :moved_by)
  end

  def currently_with_customer?
    bookings.exists?(status: [:confirmed, :paid])
  end

  private

  def track_location_change
    return unless current_location.present?
    LocationHistory.track_movement(self, current_location)
  end
end
