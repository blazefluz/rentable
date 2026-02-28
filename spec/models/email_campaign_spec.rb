# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailCampaign, type: :model do
  let(:company) { create(:company) }
  let(:email_campaign) { build(:email_campaign, company: company) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:campaign_type) }
    it { should validate_presence_of(:status) }
  end

  describe 'associations' do
    it { should belong_to(:company) }
    it { should have_many(:email_sequences).dependent(:destroy) }
    it { should have_many(:email_queues).dependent(:nullify) }
  end

  describe 'enums' do
    it 'defines campaign_type enum' do
      expect(EmailCampaign.campaign_types).to include(
        'quote_followup' => 0,
        'customer_reengagement' => 1,
        'booking_reminder' => 2,
        'marketing' => 3,
        'transactional' => 4
      )
    end

    it 'defines status enum' do
      expect(EmailCampaign.statuses).to include(
        'draft' => 0,
        'scheduled' => 1,
        'active' => 2,
        'paused' => 3,
        'completed' => 4,
        'archived' => 5
      )
    end
  end

  describe 'scopes' do
    before do
      ActsAsTenant.with_tenant(company) do
        create(:email_campaign, status: :active, active: true, company: company)
        create(:email_campaign, status: :paused, active: true, company: company)
        create(:email_campaign, status: :active, active: false, company: company)
      end
    end

    it 'active_campaigns returns only active campaigns' do
      ActsAsTenant.with_tenant(company) do
        expect(EmailCampaign.active_campaigns.count).to eq(1)
      end
    end
  end

  describe '#can_send?' do
    it 'returns true when campaign is active and enabled' do
      campaign = build(:email_campaign, status: :active, active: true)
      expect(campaign.can_send?).to be true
    end

    it 'returns false when campaign is paused' do
      campaign = build(:email_campaign, status: :paused, active: true)
      expect(campaign.can_send?).to be false
    end

    it 'returns false when campaign is not active' do
      campaign = build(:email_campaign, status: :active, active: false)
      expect(campaign.can_send?).to be false
    end

    it 'returns false when start date is in the future' do
      campaign = build(:email_campaign, status: :active, active: true, starts_at: 1.day.from_now)
      expect(campaign.can_send?).to be false
    end

    it 'returns false when end date is in the past' do
      campaign = build(:email_campaign, status: :active, active: true, ends_at: 1.day.ago)
      expect(campaign.can_send?).to be false
    end
  end

  describe '#metrics' do
    let!(:campaign) { create(:email_campaign, company: company) }

    before do
      ActsAsTenant.with_tenant(company) do
        create(:email_queue, email_campaign: campaign, delivered_at: Time.current)
        create(:email_queue, email_campaign: campaign, opened_at: Time.current, delivered_at: Time.current)
        create(:email_queue, email_campaign: campaign, clicked_at: Time.current, opened_at: Time.current, delivered_at: Time.current)
        create(:email_queue, email_campaign: campaign, bounced_at: Time.current)
      end
    end

    it 'returns correct metrics' do
      metrics = campaign.metrics

      expect(metrics[:total_sent]).to eq(4)
      expect(metrics[:delivered]).to eq(3)
      expect(metrics[:opened]).to eq(2)
      expect(metrics[:clicked]).to eq(1)
      expect(metrics[:bounced]).to eq(1)
    end
  end

  describe '#open_rate' do
    let!(:campaign) { create(:email_campaign, company: company) }

    it 'calculates open rate correctly' do
      ActsAsTenant.with_tenant(company) do
        create_list(:email_queue, 10, email_campaign: campaign)
        create_list(:email_queue, 5, email_campaign: campaign, opened_at: Time.current)

        expect(campaign.open_rate).to eq(33.33) # 5/15 * 100
      end
    end

    it 'returns 0 when no emails sent' do
      expect(campaign.open_rate).to eq(0.0)
    end
  end

  describe '#click_rate' do
    let!(:campaign) { create(:email_campaign, company: company) }

    it 'calculates click rate correctly' do
      ActsAsTenant.with_tenant(company) do
        create_list(:email_queue, 10, email_campaign: campaign)
        create_list(:email_queue, 3, email_campaign: campaign, clicked_at: Time.current)

        expect(campaign.click_rate).to eq(23.08) # 3/13 * 100
      end
    end
  end

  describe 'callbacks' do
    context 'when creating a quote_followup campaign' do
      it 'creates default sequences' do
        ActsAsTenant.with_tenant(company) do
          campaign = create(:email_campaign, campaign_type: :quote_followup, company: company)

          expect(campaign.email_sequences.count).to eq(2)

          # Check by sequence_number to be deterministic
          seq_1 = campaign.email_sequences.find_by(sequence_number: 1)
          seq_2 = campaign.email_sequences.find_by(sequence_number: 2)

          expect(seq_1.send_delay_hours).to eq(72)
          expect(seq_2.send_delay_hours).to eq(168)
        end
      end
    end

    context 'when creating a non-quote_followup campaign' do
      it 'does not create default sequences' do
        ActsAsTenant.with_tenant(company) do
          campaign = create(:email_campaign, campaign_type: :marketing, company: company)

          expect(campaign.email_sequences.count).to eq(0)
        end
      end
    end
  end

  describe '#pause!' do
    it 'sets status to paused' do
      campaign = create(:email_campaign, status: :active, company: company)
      campaign.pause!
      expect(campaign.reload.status).to eq('paused')
    end
  end

  describe '#resume!' do
    it 'sets status to active' do
      campaign = create(:email_campaign, status: :paused, company: company)
      campaign.resume!
      expect(campaign.reload.status).to eq('active')
    end
  end

  describe '#complete!' do
    it 'sets status to completed' do
      campaign = create(:email_campaign, status: :active, company: company)
      campaign.complete!
      expect(campaign.reload.status).to eq('completed')
    end
  end
end
