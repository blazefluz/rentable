# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientSegment, type: :model do
  let(:company) { create(:company) }
  let(:client_segment) { build(:client_segment, company: company) }

  describe 'validations' do
    it { should validate_presence_of(:company) }
    it { should validate_presence_of(:name) }
  end

  describe 'associations' do
    it { should belong_to(:company) }
  end

  describe 'scopes' do
    before do
      ActsAsTenant.with_tenant(company) do
        @active_segment = create(:client_segment, active: true, company: company)
        @inactive_segment = create(:client_segment, active: false, company: company)
        @auto_update_segment = create(:client_segment, auto_update: true, company: company)
      end
    end

    it 'returns active segments' do
      ActsAsTenant.with_tenant(company) do
        expect(ClientSegment.active).to include(@active_segment)
        expect(ClientSegment.active).not_to include(@inactive_segment)
      end
    end

    it 'returns auto-updating segments' do
      ActsAsTenant.with_tenant(company) do
        expect(ClientSegment.auto_updating).to include(@auto_update_segment)
      end
    end
  end

  describe '#matching_clients' do
    let(:segment) { create(:client_segment, company: company) }

    context 'with lifetime_value filter' do
      it 'returns clients with high lifetime value' do
        ActsAsTenant.with_tenant(company) do
          high_value_client = create(:client,
                                      company: company,
                                      lifetime_value_cents: 1_000_000) # $10,000
          low_value_client = create(:client,
                                     company: company,
                                     lifetime_value_cents: 100_000) # $1,000

          segment.update!(filter_rules: { lifetime_value: 'high' })

          clients = segment.matching_clients

          expect(clients).to include(high_value_client)
          expect(clients).not_to include(low_value_client)
        end
      end
    end

    context 'with last_booking_date filter' do
      it 'returns dormant clients (90+ days since last booking)' do
        ActsAsTenant.with_tenant(company) do
          active_client = create(:client,
                                  company: company,
                                  last_rental_date: 30.days.ago)
          dormant_client = create(:client,
                                   company: company,
                                   last_rental_date: 120.days.ago)

          segment.update!(filter_rules: { last_booking_date: 'dormant' })

          clients = segment.matching_clients

          expect(clients).to include(dormant_client)
          expect(clients).not_to include(active_client)
        end
      end
    end

    context 'with booking_frequency filter' do
      it 'returns frequent clients' do
        ActsAsTenant.with_tenant(company) do
          frequent_client = create(:client,
                                    company: company,
                                    total_rentals: 15)
          infrequent_client = create(:client,
                                      company: company,
                                      total_rentals: 2)

          segment.update!(filter_rules: { booking_frequency: 'frequent' })

          clients = segment.matching_clients

          expect(clients).to include(frequent_client)
          expect(clients).not_to include(infrequent_client)
        end
      end
    end

    context 'with industry filter' do
      it 'returns clients in specified industry' do
        ActsAsTenant.with_tenant(company) do
          film_client = create(:client, company: company, industry: 'Film Production')
          tech_client = create(:client, company: company, industry: 'Technology')

          segment.update!(filter_rules: { industry: 'Film Production' })

          clients = segment.matching_clients

          expect(clients).to include(film_client)
          expect(clients).not_to include(tech_client)
        end
      end
    end

    context 'with multiple filters' do
      it 'returns clients matching all conditions' do
        ActsAsTenant.with_tenant(company) do
          matching_client = create(:client,
                                    company: company,
                                    lifetime_value_cents: 1_500_000,
                                    total_rentals: 20,
                                    industry: 'Film Production')
          non_matching_client = create(:client,
                                         company: company,
                                         lifetime_value_cents: 1_500_000,
                                         total_rentals: 20,
                                         industry: 'Technology')

          segment.update!(filter_rules: {
                            lifetime_value: 'high',
                            booking_frequency: 'frequent',
                            industry: 'Film Production'
                          })

          clients = segment.matching_clients

          expect(clients).to include(matching_client)
          expect(clients).not_to include(non_matching_client)
        end
      end
    end
  end

  describe '#client_count' do
    let(:segment) { create(:client_segment, company: company) }

    it 'returns count of matching clients' do
      ActsAsTenant.with_tenant(company) do
        create_list(:client, 3,
                    company: company,
                    lifetime_value_cents: 1_000_000)
        create(:client,
               company: company,
               lifetime_value_cents: 100_000)

        segment.update!(filter_rules: { lifetime_value: 'high' })

        expect(segment.client_count).to eq(3)
      end
    end

    it 'returns 0 when no clients match' do
      ActsAsTenant.with_tenant(company) do
        create_list(:client, 2,
                    company: company,
                    lifetime_value_cents: 100_000)

        segment.update!(filter_rules: { lifetime_value: 'high' })

        expect(segment.client_count).to eq(0)
      end
    end
  end

  describe '#refresh!' do
    let(:segment) { create(:client_segment, company: company, auto_update: true) }

    it 'updates the client count cache' do
      ActsAsTenant.with_tenant(company) do
        create_list(:client, 5,
                    company: company,
                    lifetime_value_cents: 1_000_000)

        segment.update!(filter_rules: { lifetime_value: 'high' })

        expect {
          segment.refresh!
        }.to change { segment.reload.client_count }.to(5)
      end
    end
  end

  describe '#add_client' do
    let(:segment) { create(:client_segment, company: company, auto_update: false) }
    let(:client) { create(:client, company: company) }

    it 'adds a client to the segment' do
      ActsAsTenant.with_tenant(company) do
        expect {
          segment.add_client(client)
        }.to change { segment.matching_clients.count }.by(1)
      end
    end

    it 'does not add duplicate clients' do
      ActsAsTenant.with_tenant(company) do
        segment.add_client(client)

        expect {
          segment.add_client(client)
        }.not_to change { segment.matching_clients.count }
      end
    end
  end

  describe '#remove_client' do
    let(:segment) { create(:client_segment, company: company, auto_update: false) }
    let(:client) { create(:client, company: company) }

    before do
      ActsAsTenant.with_tenant(company) do
        segment.add_client(client)
      end
    end

    it 'removes a client from the segment' do
      ActsAsTenant.with_tenant(company) do
        expect {
          segment.remove_client(client)
        }.to change { segment.matching_clients.count }.by(-1)
      end
    end
  end

  describe '#clients_added_since' do
    let(:segment) { create(:client_segment, company: company) }

    it 'returns clients added after specified date' do
      ActsAsTenant.with_tenant(company) do
        old_client = create(:client,
                            company: company,
                            first_rental_date: 10.days.ago,
                            lifetime_value_cents: 1_000_000)
        new_client = create(:client,
                            company: company,
                            first_rental_date: 2.days.ago,
                            lifetime_value_cents: 1_000_000)

        segment.update!(filter_rules: { lifetime_value: 'high' })

        recent_clients = segment.clients_added_since(5.days.ago)

        expect(recent_clients).to include(new_client)
        expect(recent_clients).not_to include(old_client)
      end
    end
  end

  describe '#export_to_csv' do
    let(:segment) { create(:client_segment, company: company) }

    it 'generates CSV with client data' do
      ActsAsTenant.with_tenant(company) do
        create(:client, company: company, name: 'Acme Corp', email: 'acme@example.com')

        segment.update!(filter_rules: {})
        csv = segment.export_to_csv

        expect(csv).to include('Acme Corp')
        expect(csv).to include('acme@example.com')
      end
    end
  end
end
