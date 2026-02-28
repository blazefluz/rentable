# == Schema Information
#
# Table name: expenses
#
#  id              :bigint           not null, primary key
#  company_id      :bigint           not null
#  category        :integer          not null
#  amount_cents    :integer          not null
#  amount_currency :string           default("USD"), not null
#  date            :date             not null
#  vendor          :string
#  invoice_number  :string
#  description     :text
#  notes           :text
#  payment_method  :string
#  payment_date    :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Expense < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :company
  has_many_attached :receipts

  # Money
  monetize :amount_cents

  # Enums
  enum :category, {
    maintenance: 0,
    delivery: 1,
    marketing: 2,
    salaries: 3,
    rent: 4,
    utilities: 5,
    insurance: 6,
    supplies: 7,
    equipment_purchase: 8,
    software: 9,
    professional_services: 10,
    travel: 11,
    other: 12
  }

  # Validations
  validates :category, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :description, presence: true

  # Scopes
  scope :for_period, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :recent, -> { order(date: :desc, created_at: :desc) }
  scope :paid, -> { where.not(payment_date: nil) }
  scope :unpaid, -> { where(payment_date: nil) }

  # Class Methods
  def self.total_for_period(start_date, end_date)
    for_period(start_date, end_date).sum(:amount_cents)
  end

  def self.by_category_summary(start_date, end_date)
    for_period(start_date, end_date)
      .group(:category)
      .sum(:amount_cents)
      .transform_values { |cents| Money.new(cents, 'USD') }
  end

  # Instance Methods
  def paid?
    payment_date.present?
  end

  def overdue?
    unpaid? && date < Date.current
  end

  def unpaid?
    !paid?
  end

  def age_in_days
    return 0 if paid?
    (Date.current - date).to_i
  end
end
