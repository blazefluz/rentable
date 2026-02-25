require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { should have_many(:kit_items).dependent(:destroy) }
    it { should have_many(:kits).through(:kit_items) }
    it { should have_many(:booking_line_items) }
    it { should belong_to(:storage_location).optional }
    it { should belong_to(:product_type).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_numericality_of(:daily_price_cents).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
  end

  describe 'monetization' do
    let(:product) { create(:product, daily_price_cents: 5000) }

    it 'monetizes daily_price_cents' do
      expect(product.daily_price).to be_a(Money)
      expect(product.daily_price.cents).to eq(5000)
    end
  end

  describe '#available?' do
    let(:product) { create(:product, quantity: 3) }

    context 'when no bookings overlap' do
      it 'returns true' do
        start_date = 10.days.from_now
        end_date = 15.days.from_now
        expect(product.available?(start_date, end_date, 1)).to be true
      end
    end

    context 'when bookings overlap' do
      let!(:booking) { create(:booking, start_date: 3.days.from_now, end_date: 7.days.from_now) }
      let!(:line_item) { create(:booking_line_item, booking: booking, bookable: product, quantity: 2) }

      it 'returns true if quantity is available' do
        start_date = 4.days.from_now
        end_date = 6.days.from_now
        expect(product.available?(start_date, end_date, 1)).to be true
      end

      it 'returns false if quantity is not available' do
        start_date = 4.days.from_now
        end_date = 6.days.from_now
        expect(product.available?(start_date, end_date, 2)).to be false
      end
    end
  end

  describe '#available_quantity' do
    let(:product) { create(:product, quantity: 5) }

    it 'returns total quantity when no bookings' do
      start_date = 10.days.from_now
      end_date = 15.days.from_now
      expect(product.available_quantity(start_date, end_date)).to eq(5)
    end

    it 'returns available quantity after bookings' do
      booking = create(:booking, start_date: 3.days.from_now, end_date: 7.days.from_now)
      create(:booking_line_item, booking: booking, bookable: product, quantity: 2)

      start_date = 4.days.from_now
      end_date = 6.days.from_now
      expect(product.available_quantity(start_date, end_date)).to eq(3)
    end
  end

  describe 'scopes' do
    let!(:active_product) { create(:product, active: true) }
    let!(:inactive_product) { create(:product, :inactive) }

    it 'returns active products' do
      expect(Product.where(active: true)).to include(active_product)
      expect(Product.where(active: true)).not_to include(inactive_product)
    end
  end
end
