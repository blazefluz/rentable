class ClientSurvey < ApplicationRecord
  belongs_to :client
  belongs_to :booking, optional: true

  # Enums
  enum :survey_type, {
    post_booking: 0,
    annual: 1,
    relationship: 2,
    product_specific: 3,
    general_feedback: 4
  }

  # Validations
  validates :survey_type, presence: true
  validates :nps_score, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :satisfaction_score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true

  # Scopes
  scope :completed, -> { where.not(survey_completed_at: nil) }
  scope :pending, -> { where(survey_completed_at: nil) }
  scope :promoters, -> { where('nps_score >= ?', 9) }
  scope :passives, -> { where(nps_score: 7..8) }
  scope :detractors, -> { where('nps_score <= ?', 6) }
  scope :recent, -> { order(survey_completed_at: :desc) }
  scope :by_type, ->(type) { where(survey_type: type) }

  # Callbacks
  after_update :calculate_response_time, if: :saved_change_to_survey_completed_at?

  # Class methods
  def self.calculate_nps
    return 0 if completed.count.zero?

    total = completed.where.not(nps_score: nil).count
    return 0 if total.zero?

    promoter_pct = (promoters.count.to_f / total) * 100
    detractor_pct = (detractors.count.to_f / total) * 100
    (promoter_pct - detractor_pct).round(2)
  end

  def self.average_satisfaction
    completed.where.not(satisfaction_score: nil).average(:satisfaction_score).to_f.round(2)
  end

  def self.average_response_time_hours
    completed.where.not(response_time_hours: nil).average(:response_time_hours).to_f.round(2)
  end

  # Instance methods
  def completed?
    survey_completed_at.present?
  end

  def pending?
    !completed?
  end

  def promoter?
    nps_score.present? && nps_score >= 9
  end

  def passive?
    nps_score.present? && nps_score.between?(7, 8)
  end

  def detractor?
    nps_score.present? && nps_score <= 6
  end

  def nps_category
    return nil unless nps_score
    return 'promoter' if promoter?
    return 'passive' if passive?
    'detractor'
  end

  def satisfaction_level
    return nil unless satisfaction_score
    case satisfaction_score
    when 5 then 'very_satisfied'
    when 4 then 'satisfied'
    when 3 then 'neutral'
    when 2 then 'dissatisfied'
    when 1 then 'very_dissatisfied'
    end
  end

  def overdue?
    return false if completed?
    return false unless survey_sent_at
    survey_sent_at < 7.days.ago
  end

  def send_survey!
    self.survey_sent_at = Time.current
    save!
    # TODO: Implement email sending
    # ClientSurveyMailer.survey_request(self).deliver_later
  end

  def submit_response!(params)
    update!(
      nps_score: params[:nps_score],
      satisfaction_score: params[:satisfaction_score],
      feedback: params[:feedback],
      would_recommend: params[:would_recommend],
      survey_completed_at: Time.current
    )
  end

  private

  def calculate_response_time
    return unless survey_sent_at && survey_completed_at
    self.response_time_hours = ((survey_completed_at - survey_sent_at) / 1.hour).round
    save! if response_time_hours_changed?
  end
end
