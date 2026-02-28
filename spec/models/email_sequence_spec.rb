# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailSequence, type: :model do
  let(:company) { create(:company) }
  let(:email_campaign) { create(:email_campaign, company: company) }
  let(:email_sequence) { build(:email_sequence, email_campaign: email_campaign) }

  describe 'validations' do
    it { should validate_presence_of(:email_campaign) }
    it { should validate_presence_of(:sequence_number) }
    it { should validate_presence_of(:subject_template) }
    it { should validate_presence_of(:body_template) }
    it { should validate_presence_of(:send_delay_hours) }
  end

  describe 'associations' do
    it { should belong_to(:email_campaign) }
    it { should have_many(:email_queues).dependent(:nullify) }
  end

  describe '#substitute_variables' do
    let(:sequence) { build(:email_sequence) }

    it 'replaces placeholders with values' do
      template = "Hello {{name}}, your order {{order_id}} is ready!"
      variables = { name: 'John', order_id: '12345' }

      result = sequence.substitute_variables(template, variables)

      expect(result).to eq("Hello John, your order 12345 is ready!")
    end

    it 'leaves unreplaced placeholders unchanged' do
      template = "Hello {{name}}, your order {{order_id}} is ready!"
      variables = { name: 'John' }

      result = sequence.substitute_variables(template, variables)

      expect(result).to eq("Hello John, your order {{order_id}} is ready!")
    end
  end

  describe '#render_subject' do
    let(:sequence) do
      build(:email_sequence,
            subject_template: "Quote {{quote_number}} for {{customer_name}}")
    end

    it 'renders subject with variables' do
      variables = { quote_number: 'Q-123', customer_name: 'Acme Corp' }

      result = sequence.render_subject(variables)

      expect(result).to eq("Quote Q-123 for Acme Corp")
    end
  end

  describe '#render_body' do
    let(:sequence) do
      build(:email_sequence,
            body_template: "Hi {{customer_name}}, your quote is {{amount}}.")
    end

    it 'renders body with variables' do
      variables = { customer_name: 'John', amount: '$500' }

      result = sequence.render_body(variables)

      expect(result).to eq("Hi John, your quote is $500.")
    end
  end

  describe '#can_send?' do
    it 'returns true when sequence and campaign can send' do
      campaign = build(:email_campaign, status: :active, active: true)
      sequence = build(:email_sequence, email_campaign: campaign, active: true)

      expect(sequence.can_send?).to be true
    end

    it 'returns false when sequence is inactive' do
      campaign = build(:email_campaign, status: :active, active: true)
      sequence = build(:email_sequence, email_campaign: campaign, active: false)

      expect(sequence.can_send?).to be false
    end

    it 'returns false when campaign cannot send' do
      campaign = build(:email_campaign, status: :paused, active: true)
      sequence = build(:email_sequence, email_campaign: campaign, active: true)

      expect(sequence.can_send?).to be false
    end
  end

  describe '#schedule_for' do
    let(:campaign) { create(:email_campaign, status: :active, active: true, company: company) }
    let(:sequence) { create(:email_sequence, email_campaign: campaign, send_delay_hours: 24, active: true) }

    it 'creates an email queue entry' do
      ActsAsTenant.with_tenant(company) do
        expect {
          sequence.schedule_for(
            'customer@example.com',
            { customer_name: 'John', quote_number: 'Q-123' }
          )
        }.to change(EmailQueue, :count).by(1)
      end
    end

    it 'sets the correct recipient and subject' do
      ActsAsTenant.with_tenant(company) do
        sequence.update!(subject_template: "Quote {{quote_number}}")

        email = sequence.schedule_for(
          'customer@example.com',
          { customer_name: 'John', quote_number: 'Q-123' }
        )

        expect(email.recipient).to eq('customer@example.com')
        expect(email.subject).to eq('Quote Q-123')
      end
    end

    it 'does not create email when sequence cannot send' do
      ActsAsTenant.with_tenant(company) do
        sequence.update!(active: false)

        expect {
          sequence.schedule_for('customer@example.com', {})
        }.not_to change(EmailQueue, :count)
      end
    end
  end

  describe '#metrics' do
    let(:campaign) { create(:email_campaign, company: company) }
    let(:sequence) { create(:email_sequence, email_campaign: campaign) }

    before do
      ActsAsTenant.with_tenant(company) do
        create(:email_queue, email_sequence: sequence, delivered_at: Time.current)
        create(:email_queue, email_sequence: sequence, opened_at: Time.current)
        create(:email_queue, email_sequence: sequence, clicked_at: Time.current)
      end
    end

    it 'returns correct metrics' do
      metrics = sequence.metrics

      expect(metrics[:total_sent]).to eq(3)
      expect(metrics[:delivered]).to eq(1)
      expect(metrics[:opened]).to eq(1)
      expect(metrics[:clicked]).to eq(1)
    end
  end

  describe '#open_rate' do
    let(:campaign) { create(:email_campaign, company: company) }
    let(:sequence) { create(:email_sequence, email_campaign: campaign) }

    it 'calculates open rate correctly' do
      ActsAsTenant.with_tenant(company) do
        create_list(:email_queue, 5, email_sequence: sequence)
        create_list(:email_queue, 2, email_sequence: sequence, opened_at: Time.current)

        expect(sequence.open_rate).to eq(28.57) # 2/7 * 100
      end
    end
  end
end
