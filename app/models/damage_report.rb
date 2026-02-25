class DamageReport < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :booking
  belongs_to :product
  belongs_to :reported_by, class_name: "User"
  has_many_attached :damage_photos

  # Enums
  enum :severity, {
    minor: 0,        # Cosmetic, doesn't affect function
    moderate: 1,     # Affects function but still usable
    major: 2,        # Significant damage, limited usability
    critical: 3,     # Not usable, needs major repair
    total_loss: 4    # Beyond repair
  }, prefix: true

  # Monetize
  monetize :repair_cost_cents, as: :repair_cost, with_model_currency: :repair_cost_currency, allow_nil: true

  # Validations
  validates :description, presence: true
  validates :severity, presence: true

  # Scopes
  scope :unresolved, -> { where(resolved: false) }
  scope :resolved, -> { where(resolved: true) }
  scope :by_severity, ->(severity) { where(severity: severity) if severity.present? }
  scope :critical, -> { where(severity: [:critical, :total_loss]) }
  scope :recent, -> { order(created_at: :desc) }

  # Mark as resolved
  def resolve!(notes = nil)
    update(
      resolved: true,
      resolved_at: Time.current,
      resolution_notes: notes
    )
  end

  # Check if repair cost exceeds threshold
  def exceeds_threshold?(threshold_cents)
    repair_cost_cents.present? && repair_cost_cents > threshold_cents
  end
end
