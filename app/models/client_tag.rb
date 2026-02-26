class ClientTag < ApplicationRecord
  # Associations
  has_many :client_taggings, dependent: :destroy
  has_many :clients, through: :client_taggings

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }
  scope :by_usage, -> { left_joins(:client_taggings).group(:id).order('COUNT(client_taggings.id) DESC') }

  # Callbacks
  before_validation :set_defaults
  before_validation :normalize_name

  # Instance methods
  def usage_count
    client_taggings.count
  end

  def clients_count
    clients.count
  end

  def display_name
    icon.present? ? "#{icon} #{name}" : name
  end

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  private

  def set_defaults
    self.active = true if active.nil?
    self.color ||= generate_random_color
  end

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def generate_random_color
    "##{SecureRandom.hex(3)}"
  end
end
