# == Schema Information
#
# Table name: expense_budgets
#
#  id                       :bigint           not null, primary key
#  company_id               :bigint           not null
#  category                 :integer          not null
#  period_type              :integer          not null
#  budgeted_amount_cents    :integer          not null
#  budgeted_amount_currency :string           default("USD"), not null
#  start_date               :date             not null
#  end_date                 :date             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class ExpenseBudget < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :company

  # Money
  monetize :budgeted_amount_cents

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

  enum :period_type, {
    monthly: 0,
    quarterly: 1,
    annual: 2,
    custom: 3
  }

  # Validations
  validates :category, presence: true
  validates :period_type, presence: true
  validates :budgeted_amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Instance Methods
  def actual_spent
    Expense.where(company: company)
           .where(category: category)
           .for_period(start_date, end_date)
           .sum(:amount_cents)
  end

  def actual_spent_money
    Money.new(actual_spent, budgeted_amount_currency)
  end

  def remaining_budget
    budgeted_amount - actual_spent_money
  end

  def percentage_used
    return 0 if budgeted_amount_cents.zero?
    (actual_spent.to_f / budgeted_amount_cents * 100).round(2)
  end

  def over_budget?
    actual_spent > budgeted_amount_cents
  end

  def variance
    actual_spent_money - budgeted_amount
  end

  def variance_percentage
    return 0 if budgeted_amount_cents.zero?
    ((variance.cents.to_f / budgeted_amount_cents) * 100).round(2)
  end

  def approaching_limit?(threshold = 80)
    percentage_used >= threshold
  end

  def period_description
    case period_type
    when 'monthly'
      start_date.strftime('%B %Y')
    when 'quarterly'
      "Q#{((start_date.month - 1) / 3) + 1} #{start_date.year}"
    when 'annual'
      start_date.year.to_s
    when 'custom'
      "#{start_date.strftime('%b %d')} - #{end_date.strftime('%b %d, %Y')}"
    end
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
end
