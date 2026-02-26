class Lead < ApplicationRecord
  # Associations
  belongs_to :assigned_to, class_name: 'User', foreign_key: 'assigned_to_id', optional: true
  belongs_to :converted_to_client, class_name: 'Client', foreign_key: 'converted_to_client_id', optional: true
  has_many :bookings, dependent: :nullify

  # Money fields
  monetize :expected_value_cents, allow_nil: true

  # Enums
  enum :status, {
    new_lead: 0,
    contacted: 1,
    qualified: 2,
    proposal_sent: 3,
    negotiation: 4,
    won: 5,
    lost: 6,
    nurturing: 7
  }

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A[\d\s\-\+\(\)\.]+\z/ }, allow_blank: true
  validates :probability, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_blank: true
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: [:new_lead, :contacted, :qualified, :proposal_sent, :negotiation, :nurturing]) }
  scope :open, -> { where.not(status: [:won, :lost]) }
  scope :won, -> { where(status: :won) }
  scope :lost, -> { where(status: :lost) }
  scope :assigned_to_user, ->(user_id) { where(assigned_to_id: user_id) }
  scope :by_source, ->(source) { where(source: source) }
  scope :closing_soon, -> { where('expected_close_date <= ?', 30.days.from_now).open }
  scope :overdue, -> { where('expected_close_date < ?', Date.today).open }
  scope :high_value, -> { where('expected_value_cents >= ?', 100_000_00) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_save :calculate_weighted_value
  after_update :handle_status_change

  # Instance methods
  def convert_to_client!(client = nil)
    transaction do
      if client.nil?
        client = Client.create!(
          name: company.presence || name,
          contact_name: name,
          email: email,
          phone: phone,
          notes: "Converted from lead ##{id}\n\n#{notes}"
        )
      end

      update!(
        status: :won,
        converted_to_client_id: client.id,
        converted_at: Time.current
      )

      # Update any associated bookings
      bookings.update_all(client_id: client.id)

      client
    end
  end

  def mark_as_lost!(reason = nil)
    update!(
      status: :lost,
      lost_reason: reason
    )
  end

  def weighted_value
    return Money.new(0, expected_value_currency || 'USD') unless expected_value && probability

    Money.new((expected_value_cents * probability / 100.0).to_i, expected_value_currency || 'USD')
  end

  def days_until_close
    return nil unless expected_close_date
    (expected_close_date - Date.today).to_i
  end

  def overdue?
    expected_close_date.present? && expected_close_date < Date.today && open?
  end

  def open?
    !won? && !lost?
  end

  def contactable?
    email.present? || phone.present?
  end

  def stage_duration
    return nil unless created_at && updated_at
    ((updated_at - created_at) / 1.day).round
  end

  private

  def calculate_weighted_value
    # This is automatically calculated via weighted_value method
    # We could cache it if needed
  end

  def handle_status_change
    return unless saved_change_to_status?

    case status
    when 'won'
      self.converted_at ||= Time.current
    when 'lost'
      self.converted_at = nil
      self.converted_to_client_id = nil
    end
  end
end
