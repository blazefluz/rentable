require 'rails_helper'

RSpec.describe Kit, type: :model do
  describe 'associations' do
    it { should have_many(:kit_items).dependent(:destroy) }
    it { should have_many(:products).through(:kit_items) }
    it { should have_many(:booking_line_items) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_numericality_of(:daily_price_cents).is_greater_than_or_equal_to(0) }
  end

  describe 'monetization' do
    let(:kit) { create(:kit, daily_price_cents: 10000) }

    it 'monetizes daily_price_cents' do
      expect(kit.daily_price).to be_a(Money)
      expect(kit.daily_price.cents).to eq(10000)
    end
  end

  describe '#available?' do
    let(:kit) { create(:kit, :with_items) }

    context 'when all products are available' do
      it 'returns true' do
        start_date = 10.days.from_now
        end_date = 15.days.from_now
        expect(kit.available?(start_date, end_date, 1)).to be true
      end
    end

    context 'when any product is unavailable' do
      let!(:booking) { create(:booking, start_date: 3.days.from_now, end_date: 7.days.from_now) }

      before do
        product = kit.products.first
        create(:booking_line_item, booking: booking, bookable: product, quantity: product.quantity)
      end

      it 'returns false' do
        start_date = 4.days.from_now
        end_date = 6.days.from_now
        expect(kit.available?(start_date, end_date, 1)).to be false
      end
    end
  end

  describe '#available_quantity' do
    let(:kit) { create(:kit, :with_items) }

    it 'returns the minimum available quantity across all products' do
      start_date = 10.days.from_now
      end_date = 15.days.from_now

      min_quantity = kit.products.map(&:quantity).min
      expect(kit.available_quantity(start_date, end_date)).to eq(min_quantity)
    end
  end
end
