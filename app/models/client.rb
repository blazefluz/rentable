class Client < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  has_many :bookings, dependent: :nullify
  has_many :locations, dependent: :destroy
  has_many :business_entities, dependent: :destroy
  has_many :addresses, as: :addressable, dependent: :destroy
  has_many :sales_tasks, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy
  has_many_attached :attachments

  # CRM Associations
  has_many :contacts, dependent: :destroy
  has_many :client_communications, dependent: :destroy
  has_many :client_taggings, dependent: :destroy
  has_many :client_tags, through: :client_taggings
  has_many :client_metrics, dependent: :destroy
  belongs_to :account_manager, class_name: 'User', foreign_key: 'account_manager_id', optional: true

  # New CRM Enhancements
  has_many :client_users, dependent: :destroy
  has_many :service_agreements, dependent: :destroy
  has_many :client_surveys, dependent: :destroy
  belongs_to :parent_client, class_name: 'Client', foreign_key: 'parent_client_id', optional: true
  has_many :child_clients, class_name: 'Client', foreign_key: 'parent_client_id', dependent: :nullify

  # Money
  monetize :account_value_cents, allow_nil: true, with_model_currency: :account_value_currency
  monetize :credit_limit_cents, allow_nil: true, with_model_currency: :credit_limit_currency
  monetize :outstanding_balance_cents, allow_nil: true, with_model_currency: :outstanding_balance_currency
  monetize :lifetime_value_cents, allow_nil: true, with_model_currency: :lifetime_value_currency
  monetize :average_booking_value_cents, allow_nil: true, with_model_currency: :average_booking_value_currency

  # Enums
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    vip: 3
  }

  enum :credit_status, {
    pending_approval: 0,
    approved: 1,
    suspended: 2,
    revoked: 3
  }, prefix: true

  enum :churn_risk, {
    low_risk: 0,
    medium_risk: 1,
    high_risk: 2,
    critical_risk: 3
  }, prefix: true

  enum :priority_level, {
    priority_low: 0,
    priority_medium: 1,
    priority_high: 2,
    priority_critical: 3
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, uniqueness: { case_sensitive: false }, if: -> { email.present? }

  # Scopes
  scope :active, -> { where(archived: false, deleted: false) }
  scope :archived, -> { where(archived: true) }
  scope :search, ->(query) { where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_position, -> { order(position: :asc) }

  # CRM Scopes
  scope :with_credit_approved, -> { where(credit_status: :approved) }
  scope :credit_suspended, -> { where(credit_status: :suspended) }
  scope :by_industry, ->(industry) { where(industry: industry) }
  scope :by_segment, ->(segment) { where(market_segment: segment) }
  scope :by_service_tier, ->(tier) { where(service_tier: tier) }
  scope :high_value, -> { where('lifetime_value_cents >= ?', 100_000_00) }
  scope :at_risk, -> { where(churn_risk: [:high_risk, :critical_risk]) }
  scope :with_tag, ->(tag_name) { joins(:client_tags).where(client_tags: { name: tag_name }) }
  scope :inactive, -> { where('last_activity_at < ?', 90.days.ago) }
  scope :recently_active, -> { where('last_activity_at >= ?', 30.days.ago) }
  scope :new_clients, -> { where('created_at >= ?', 30.days.ago) }

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end

  def archive!
    update(archived: true)
  end

  def unarchive!
    update(archived: false)
  end

  # Calculate total value from completed bookings
  def calculate_account_value
    total = bookings.where(status: [:confirmed, :completed]).sum(:total_price_cents)
    update(
      account_value_cents: total,
      account_value_currency: bookings.first&.total_price_currency || 'USD'
    )
  end

  # CRM Methods
  def primary_contact
    contacts.find_by(is_primary: true) || contacts.first
  end

  def add_tag(tag_name, tagged_by: nil)
    tag = ClientTag.find_or_create_by!(name: tag_name.to_s.titleize)
    client_taggings.find_or_create_by!(client_tag: tag, tagged_by: tagged_by)
  end

  def remove_tag(tag_name)
    tag = ClientTag.find_by(name: tag_name.to_s.titleize)
    return false unless tag

    client_taggings.find_by(client_tag: tag)&.destroy
    true
  end

  def tag_names
    client_tags.pluck(:name)
  end

  def calculate_lifetime_value
    total = bookings.where(status: [:completed, :confirmed]).sum(:total_price_cents)
    update(
      lifetime_value_cents: total,
      lifetime_value_currency: 'USD'
    )
  end

  def calculate_average_booking_value
    completed = bookings.where(status: [:completed, :confirmed])
    total = completed.count
    return if total.zero?

    avg = completed.sum(:total_price_cents) / total
    update(
      average_booking_value_cents: avg,
      average_booking_value_currency: 'USD'
    )
  end

  def update_lifecycle_metrics!
    completed = bookings.where(status: [:completed, :confirmed])

    update!(
      first_rental_date: completed.minimum(:start_date),
      last_rental_date: completed.maximum(:start_date),
      total_rentals: completed.count,
      lifetime_value_cents: completed.sum(:total_price_cents),
      average_booking_value_cents: completed.count > 0 ? completed.sum(:total_price_cents) / completed.count : 0,
      health_score: calculate_health_score
    )
  end

  def calculate_health_score
    score = 50 # Start at neutral

    # Positive factors
    score += 10 if total_rentals.to_i > 10
    score += 10 if last_rental_date && last_rental_date > 30.days.ago
    score += 10 if lifetime_value_cents.to_i > 50_000_00
    score += 10 if outstanding_balance_cents.to_i < 1000_00
    score += 10 if credit_status_approved?

    # Negative factors
    score -= 20 if last_rental_date && last_rental_date < 90.days.ago
    score -= 15 if outstanding_balance_cents.to_i > credit_limit_cents.to_i
    score -= 10 if credit_status_suspended? || credit_status_revoked?

    [[score, 0].max, 100].min # Clamp between 0 and 100
  end

  def calculate_churn_risk
    return :low_risk unless last_rental_date

    days_since_rental = (Date.today - last_rental_date).to_i

    if days_since_rental > 180
      :critical_risk
    elsif days_since_rental > 120
      :high_risk
    elsif days_since_rental > 60
      :medium_risk
    else
      :low_risk
    end
  end

  def has_available_credit?
    return false unless credit_status_approved?
    return true if credit_limit_cents.nil?

    outstanding_balance_cents.to_i < credit_limit_cents.to_i
  end

  def available_credit
    return Money.new(0, 'USD') unless credit_status_approved?
    return Money.new(Float::INFINITY, 'USD') if credit_limit_cents.nil?

    Money.new([credit_limit_cents - outstanding_balance_cents.to_i, 0].max, credit_limit_currency || 'USD')
  end

  def log_communication!(type:, direction:, subject:, notes: nil, user:, contact: nil)
    client_communications.create!(
      communication_type: type,
      direction: direction,
      subject: subject,
      notes: notes,
      user: user,
      contact: contact || primary_contact,
      communicated_at: Time.current
    )
  end

  def recent_communications(limit = 10)
    client_communications.recent.limit(limit)
  end

  def days_since_last_rental
    return nil unless last_rental_date
    (Date.today - last_rental_date).to_i
  end

  def active?
    last_activity_at.present? && last_activity_at > 90.days.ago
  end

  # Client Portal Methods
  def create_portal_user!(contact)
    client_users.create!(
      contact: contact,
      email: contact.email,
      active: true
    )
  end

  def portal_users_count
    client_users.active.count
  end

  # Service Agreement Methods
  def active_agreement
    service_agreements.active.first
  end

  def has_active_agreement?
    service_agreements.active.exists?
  end

  # Survey Methods
  def average_nps_score
    client_surveys.completed.where.not(nps_score: nil).average(:nps_score).to_f.round(2)
  end

  def latest_nps_score
    client_surveys.completed.where.not(nps_score: nil).order(survey_completed_at: :desc).first&.nps_score
  end

  # Hierarchy Methods
  def has_parent?
    parent_client_id.present?
  end

  def has_children?
    child_clients.exists?
  end

  def all_child_clients
    child_clients + child_clients.flat_map(&:all_child_clients)
  end

  def root_parent
    return self unless has_parent?
    parent_client.root_parent
  end

  # Duplicate Detection
  def self.find_duplicates(threshold = 0.8)
    duplicates = []

    Client.find_each do |client|
      similar = Client.where.not(id: client.id)
                     .where("similarity(name, ?) > ?", client.name, threshold)
                     .or(Client.where(email: client.email).where.not(id: client.id))
                     .or(Client.where(phone: client.phone).where.not(id: client.id).where.not(phone: [nil, '']))

      duplicates << { client: client, matches: similar } if similar.any?
    end

    duplicates
  rescue => e
    # Fallback if pg_trgm extension not available
    find_duplicates_simple
  end

  def self.find_duplicates_simple
    duplicates = []

    # Email duplicates
    Client.group(:email).having('COUNT(*) > 1').pluck(:email).each do |email|
      next if email.blank?
      matches = Client.where(email: email)
      duplicates << { type: 'email', value: email, clients: matches }
    end

    # Phone duplicates
    Client.group(:phone).having('COUNT(*) > 1').pluck(:phone).each do |phone|
      next if phone.blank?
      matches = Client.where(phone: phone)
      duplicates << { type: 'phone', value: phone, clients: matches }
    end

    duplicates
  end

  def merge_with!(other_client, keep: :self)
    raise ArgumentError, "Cannot merge client with itself" if self.id == other_client.id

    primary = keep == :self ? self : other_client
    secondary = keep == :self ? other_client : self

    transaction do
      # Merge bookings
      secondary.bookings.update_all(client_id: primary.id)

      # Merge contacts (avoid duplicates)
      secondary.contacts.each do |contact|
        unless primary.contacts.exists?(email: contact.email)
          contact.update!(client_id: primary.id)
        end
      end

      # Merge communications
      secondary.client_communications.update_all(client_id: primary.id)

      # Merge tags
      secondary.client_taggings.each do |tagging|
        primary.add_tag(tagging.client_tag.name, tagged_by: tagging.tagged_by) rescue nil
      end

      # Merge metrics
      secondary.client_metrics.update_all(client_id: primary.id)

      # Merge surveys
      secondary.client_surveys.update_all(client_id: primary.id)

      # Merge service agreements
      secondary.service_agreements.update_all(client_id: primary.id)

      # Combine notes
      if secondary.notes_text.present?
        primary.notes_text = "#{primary.notes_text}\n\n--- Merged from #{secondary.name} (##{secondary.id}) ---\n#{secondary.notes_text}"
        primary.save!
      end

      # Update lifecycle metrics
      primary.update_lifecycle_metrics!

      # Mark secondary as deleted
      secondary.update!(
        archived: true,
        deleted: true,
        name: "#{secondary.name} [MERGED into ##{primary.id}]"
      )

      primary
    end
  end

  after_initialize :set_defaults

  private

  def set_defaults
    self.priority ||= :medium
    self.account_value_currency ||= 'USD'
    self.credit_limit_currency ||= 'USD'
    self.outstanding_balance_currency ||= 'USD'
    self.lifetime_value_currency ||= 'USD'
    self.average_booking_value_currency ||= 'USD'
  end
end
