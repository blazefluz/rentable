# == Schema Information
#
# Table name: financial_reports
#
#  id             :bigint           not null, primary key
#  company_id     :bigint           not null
#  report_type    :integer          not null
#  period_type    :integer          not null
#  start_date     :date             not null
#  end_date       :date             not null
#  data           :jsonb            not null
#  generated_at   :datetime         not null
#  generated_by_id :bigint
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class FinancialReport < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :company
  belongs_to :generated_by, class_name: 'User', optional: true

  # Enums
  enum :report_type, {
    profit_loss: 0,
    balance_sheet: 1,
    cash_flow: 2,
    revenue_breakdown: 3,
    expense_summary: 4,
    roi_analysis: 5
  }

  enum :period_type, {
    daily: 0,
    weekly: 1,
    monthly: 2,
    quarterly: 3,
    annual: 4,
    custom: 5
  }

  # Validations
  validates :report_type, presence: true
  validates :period_type, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :data, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :recent, -> { order(generated_at: :desc) }
  scope :for_period, ->(start_date, end_date) { where('start_date >= ? AND end_date <= ?', start_date, end_date) }
  scope :by_type, ->(type) { where(report_type: type) }

  # Callbacks
  before_create :set_generated_at

  # Instance Methods
  def period_description
    case period_type
    when 'daily'
      start_date.strftime('%B %d, %Y')
    when 'weekly'
      "Week of #{start_date.strftime('%B %d, %Y')}"
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

  def total_revenue
    Money.new(data.dig('revenue', 'total') || 0, 'USD')
  end

  def total_expenses
    Money.new(data.dig('expenses', 'total') || 0, 'USD')
  end

  def net_income
    Money.new(data.dig('net_income') || 0, 'USD')
  end

  def gross_profit
    Money.new(data.dig('gross_profit') || 0, 'USD')
  end

  def gross_margin_percentage
    return 0 if total_revenue.cents.zero?
    (gross_profit.cents.to_f / total_revenue.cents * 100).round(2)
  end

  def net_margin_percentage
    return 0 if total_revenue.cents.zero?
    (net_income.cents.to_f / total_revenue.cents * 100).round(2)
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end

  def set_generated_at
    self.generated_at ||= Time.current
  end
end
