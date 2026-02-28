# == Schema Information
#
# Table name: scheduled_reports
#
#  id             :bigint           not null, primary key
#  company_id     :bigint           not null
#  report_type    :integer          not null
#  frequency      :integer          not null
#  recipients     :jsonb            not null
#  format         :integer          not null
#  next_send_date :date
#  active         :boolean          default(TRUE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class ScheduledReport < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :company

  # Enums
  enum :report_type, {
    profit_loss: 0,
    revenue_summary: 1,
    expense_summary: 2,
    roi_analysis: 3,
    monthly_management: 4,
    quarterly_board: 5
  }

  enum :frequency, {
    daily: 0,
    weekly: 1,
    monthly: 2,
    quarterly: 3,
    annual: 4
  }

  enum :format, {
    pdf: 0,
    csv: 1,
    excel: 2
  }

  # Validations
  validates :report_type, presence: true
  validates :frequency, presence: true
  validates :recipients, presence: true
  validates :format, presence: true
  validate :recipients_format

  # Scopes
  scope :active, -> { where(active: true) }
  scope :due, -> { active.where('next_send_date <= ?', Date.current) }

  # Callbacks
  before_create :calculate_next_send_date

  # Instance Methods
  def recipient_emails
    recipients.is_a?(Array) ? recipients : []
  end

  def calculate_next_send_date
    self.next_send_date = case frequency
    when 'daily'
      Date.current + 1.day
    when 'weekly'
      Date.current.next_week
    when 'monthly'
      Date.current.next_month.beginning_of_month
    when 'quarterly'
      Date.current.next_quarter.beginning_of_quarter
    when 'annual'
      Date.current.next_year.beginning_of_year
    end
  end

  def advance_next_send_date!
    calculate_next_send_date
    save!
  end

  def period_for_report
    end_date = next_send_date - 1.day
    start_date = case frequency
    when 'daily'
      end_date
    when 'weekly'
      end_date - 6.days
    when 'monthly'
      end_date.beginning_of_month
    when 'quarterly'
      end_date.beginning_of_quarter
    when 'annual'
      end_date.beginning_of_year
    end

    { start_date: start_date, end_date: end_date }
  end

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
    calculate_next_send_date
  end

  private

  def recipients_format
    return if recipients.blank?

    unless recipients.is_a?(Array)
      errors.add(:recipients, 'must be an array of email addresses')
      return
    end

    recipients.each do |email|
      unless email.match?(URI::MailTo::EMAIL_REGEXP)
        errors.add(:recipients, "contains invalid email: #{email}")
      end
    end
  end
end
