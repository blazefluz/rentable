require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it { should have_many(:booking_line_items).dependent(:destroy) }
    it { should have_many(:booking_comments).dependent(:destroy) }
    it { should have_many(:payments).dependent(:destroy) }
    it { should belong_to(:client).optional }
    it { should belong_to(:venue_location).optional }
    it { should belong_to(:manager).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:customer_name) }
    it { should validate_presence_of(:customer_email) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(draft: 0, pending: 1, confirmed: 2, paid: 3, cancelled: 4, completed: 5).with_prefix(:status) }
  end

  describe 'monetization' do
    let(:booking) { create(:booking, total_price_cents: 15000) }

    it 'monetizes total_price_cents' do
      expect(booking.total_price).to be_a(Money)
      expect(booking.total_price.cents).to eq(15000)
    end
  end

  describe '#rental_days' do
    let(:booking) { create(:booking, start_date: Date.today, end_date: Date.today + 5.days) }

    it 'calculates the rental days' do
      expect(booking.rental_days).to eq(6) # includes both start and end date
    end
  end

  describe 'callbacks' do
    context 'when creating a booking' do
      it 'generates a reference number' do
        booking = create(:booking)
        expect(booking.reference_number).to be_present
        expect(booking.reference_number).to match(/BK\d{8}/)
      end
    end
  end

  describe '#calculate_total_price' do
    let(:product) { create(:product, daily_price_cents: 5000) }
    let(:booking) { build(:booking, start_date: Date.today, end_date: Date.today + 2.days) }

    before do
      booking.booking_line_items.build(bookable: product, quantity: 2, price_cents: 5000)
      booking.save
    end

    it 'calculates total from line items' do
      # 3 days (includes start and end) * 2 quantity * 5000 cents
      expect(booking.total_price_cents).to eq(30000)
    end
  end
end
