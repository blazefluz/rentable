class VariantStockHistory < ApplicationRecord
  include ActsAsTenant

  # Multi-tenancy
  acts_as_tenant :company

  # Associations
  belongs_to :product_variant
  belongs_to :company
  belongs_to :user, optional: true
  belongs_to :location, optional: true

  # Polymorphic reference to related record (Booking, PurchaseOrder, etc.)
  # Note: Using string reference_type + bigint reference_id instead of polymorphic association
  # to maintain compatibility with integer-based IDs in existing tables

  # Validations
  validates :change_type, presence: true, inclusion: {
    in: %w[adjustment sale return damage restock reservation release transfer],
    message: "%{value} is not a valid change type"
  }
  validates :quantity_before, presence: true, numericality: { only_integer: true }
  validates :quantity_after, presence: true, numericality: { only_integer: true }
  validates :quantity_change, presence: true, numericality: { only_integer: true }

  validate :quantity_change_matches_before_after

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_variant, ->(variant_id) { where(product_variant_id: variant_id) }
  scope :by_type, ->(type) { where(change_type: type) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :today, -> { where('created_at >= ?', Time.zone.now.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', Time.zone.now.beginning_of_week) }
  scope :this_month, -> { where('created_at >= ?', Time.zone.now.beginning_of_month) }
  scope :between, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Display helpers
  def change_description
    case change_type
    when 'adjustment'
      if quantity_change.positive?
        "Added #{quantity_change.abs} units"
      elsif quantity_change.negative?
        "Removed #{quantity_change.abs} units"
      else
        "No change"
      end
    when 'sale'
      "Sold #{quantity_change.abs} units"
    when 'return'
      "Returned #{quantity_change.abs} units"
    when 'damage'
      "Marked #{quantity_change.abs} units as damaged"
    when 'restock'
      "Restocked #{quantity_change.abs} units"
    when 'reservation'
      "Reserved #{quantity_change.abs} units"
    when 'release'
      "Released #{quantity_change.abs} units from reservation"
    when 'transfer'
      "Transferred #{quantity_change.abs} units"
    else
      "Changed by #{quantity_change}"
    end
  end

  def change_direction
    if quantity_change.positive?
      'increase'
    elsif quantity_change.negative?
      'decrease'
    else
      'neutral'
    end
  end

  def user_name
    user&.name || 'System'
  end

  def reference_object
    return nil unless reference_type.present? && reference_id.present?

    begin
      reference_type.constantize.find_by(id: reference_id)
    rescue NameError, ActiveRecord::RecordNotFound
      nil
    end
  end

  def reference_display
    return 'N/A' unless reference_type.present? && reference_id.present?
    "#{reference_type} ##{reference_id}"
  end

  # Analytics helpers
  def self.total_stock_change(start_date: nil, end_date: nil)
    scope = all
    scope = scope.where('created_at >= ?', start_date) if start_date
    scope = scope.where('created_at <= ?', end_date) if end_date
    scope.sum(:quantity_change)
  end

  def self.changes_by_type
    group(:change_type).count
  end

  def self.changes_by_user
    joins(:user).group('users.name').count
  end

  def self.stock_timeline(start_date:, end_date:, interval: 'day')
    # Returns stock levels over time
    histories = between(start_date, end_date).order(:created_at)

    case interval
    when 'hour'
      histories.group_by { |h| h.created_at.beginning_of_hour }
    when 'day'
      histories.group_by { |h| h.created_at.to_date }
    when 'week'
      histories.group_by { |h| h.created_at.beginning_of_week }
    when 'month'
      histories.group_by { |h| h.created_at.beginning_of_month }
    else
      histories.group_by { |h| h.created_at.to_date }
    end
  end

  private

  def quantity_change_matches_before_after
    expected_change = quantity_after - quantity_before
    if quantity_change != expected_change
      errors.add(:quantity_change, "must equal quantity_after - quantity_before (expected #{expected_change}, got #{quantity_change})")
    end
  end
end
