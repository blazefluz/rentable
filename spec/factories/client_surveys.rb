FactoryBot.define do
  factory :client_survey do
    client { nil }
    booking { nil }
    survey_type { 1 }
    nps_score { 1 }
    satisfaction_score { 1 }
    feedback { "MyText" }
    would_recommend { false }
    survey_sent_at { "2026-02-26 00:12:34" }
    survey_completed_at { "2026-02-26 00:12:34" }
    response_time_hours { 1 }
  end
end
