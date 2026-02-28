require 'rails_helper'

RSpec.describe 'Api::V1::Bookings - Tax Calculations', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:client) { create(:client, company: company) }
  let(:location) { create(:location, company: company, country: 'US', state: 'CA', city: 'Los Angeles') }
  let(:product) { create(:product, company: company, quantity: 10, daily_price_cents: 10000) }

  before do
    ActsAsTenant.current_tenant = company
  end

  describe 'Tax Rate Application' do
    let(:tax_rate) do
      create(:tax_rate,
        company: company,
        name: 'CA Sales Tax',
        tax_code: 'CA-ST',
        tax_type: :sales_tax,
        rate: 0.0725,
        country: 'US',
        state: 'CA',
        active: true
      )
    end

    let(:booking) do
      create(:booking,
        company: company,
        venue_location: location,
        default_tax_rate: tax_rate,
        start_date: 3.days.from_now,
        end_date: 7.days.from_now
      )
    end

    let!(:line_item) do
      create(:booking_line_item,
        booking: booking,
        bookable: product,
        quantity: 2,
        price_cents: 10000,
        tax_rate: tax_rate,
        taxable: true
      )
    end

    context 'automatic tax calculation' do
      before do
        booking.calculate_total_price
        booking.save
      end

      it 'calculates subtotal before tax' do
        # 2 qty × 5 days × $100/day = $1,000
        expect(booking.subtotal_cents).to eq(100000)
        expect(booking.subtotal.format).to eq('$1,000.00')
      end

      it 'calculates tax amount correctly' do
        # $1,000 × 7.25% = $72.50
        expected_tax = (100000 * 0.0725).round
        expect(booking.tax_total_cents).to eq(expected_tax)
      end

      it 'calculates grand total with tax' do
        # $1,000 + $72.50 = $1,072.50
        expected_total = booking.subtotal_cents + booking.tax_total_cents
        expect(booking.grand_total_cents).to eq(expected_total)
      end

      it 'applies tax to line items' do
        line_item.calculate_tax

        # Line subtotal: $1,000
        expect(line_item.line_subtotal.cents).to eq(100000)

        # Line tax: $72.50
        expected_line_tax = (100000 * 0.0725).round
        expect(line_item.tax_amount_cents).to eq(expected_line_tax)

        # Line total with tax: $1,072.50
        expect(line_item.line_total_with_tax.cents).to eq(100000 + expected_line_tax)
      end
    end

    context 'location-based tax lookup' do
      it 'finds applicable tax rates for venue location' do
        rates = booking.applicable_tax_rates

        expect(rates).to include(tax_rate)
      end

      it 'finds tax rates by state' do
        state_tax = create(:tax_rate,
          company: company,
          name: 'CA State Tax',
          country: 'US',
          state: 'CA',
          active: true
        )

        rates = TaxRate.for_location(country: 'US', state: 'CA')

        expect(rates).to include(state_tax)
      end

      it 'finds tax rates by city' do
        city_tax = create(:tax_rate,
          company: company,
          name: 'LA City Tax',
          country: 'US',
          state: 'CA',
          city: 'Los Angeles',
          active: true
        )

        rates = TaxRate.for_location(country: 'US', state: 'CA', city: 'Los Angeles')

        expect(rates).to include(city_tax)
      end
    end

    context 'multiple tax rates (composite)' do
      let(:state_tax) do
        create(:tax_rate,
          company: company,
          name: 'CA State',
          tax_code: 'CA-STATE',
          rate: 0.0725,
          country: 'US',
          state: 'CA',
          active: true,
          component_type: :state_tax
        )
      end

      let(:county_tax) do
        create(:tax_rate,
          company: company,
          name: 'LA County',
          tax_code: 'LA-COUNTY',
          rate: 0.01,
          country: 'US',
          state: 'CA',
          city: 'Los Angeles',
          active: true,
          component_type: :county_tax
        )
      end

      let(:composite_tax) do
        create(:tax_rate,
          company: company,
          name: 'LA Total Tax',
          tax_code: 'LA-COMPOSITE',
          rate: 0.0825,
          country: 'US',
          state: 'CA',
          city: 'Los Angeles',
          active: true,
          component_type: :composite
        )
      end

      before do
        state_tax.update(parent_tax_rate: composite_tax)
        county_tax.update(parent_tax_rate: composite_tax)
        booking.update(default_tax_rate: composite_tax)
      end

      it 'breaks down composite tax into components' do
        breakdown = booking.tax_breakdown

        expect(breakdown[:tax_components]).to be_an(Array)
        expect(breakdown[:tax_components].map { |c| c[:type] }).to include(:state_tax, :county_tax)
      end
    end
  end

  describe 'Tax Exemptions' do
    let(:tax_rate) do
      create(:tax_rate,
        company: company,
        rate: 0.0725,
        country: 'US',
        active: true
      )
    end

    let(:booking) do
      create(:booking,
        company: company,
        default_tax_rate: tax_rate,
        start_date: 3.days.from_now,
        end_date: 7.days.from_now,
        total_price_cents: 100000
      )
    end

    context 'marking booking as tax exempt' do
      it 'exempts booking from tax' do
        booking.mark_tax_exempt!(
          reason: 'Non-profit organization (501c3)',
          certificate: 'CERT-12345'
        )

        expect(booking.reload.tax_exempt?).to be true
        expect(booking.tax_exempt_reason).to eq('Non-profit organization (501c3)')
        expect(booking.tax_exempt_certificate).to eq('CERT-12345')
      end

      it 'sets tax to zero when exempt' do
        booking.mark_tax_exempt!(reason: 'Tax exempt')

        expect(booking.tax_total_cents).to eq(0)
        expect(booking.grand_total_cents).to eq(booking.subtotal_cents)
      end

      it 'recalculates totals after exemption' do
        create(:booking_line_item, booking: booking, bookable: product, tax_rate: tax_rate)
        booking.calculate_total_price
        original_tax = booking.tax_total_cents

        expect(original_tax).to be > 0

        booking.mark_tax_exempt!(reason: 'Test')

        expect(booking.reload.tax_total_cents).to eq(0)
      end
    end

    context 'non-taxable line items' do
      it 'excludes non-taxable items from tax calculation' do
        taxable_item = create(:booking_line_item,
          booking: booking,
          bookable: product,
          quantity: 1,
          price_cents: 10000,
          tax_rate: tax_rate,
          taxable: true
        )

        non_taxable_item = create(:booking_line_item,
          booking: booking,
          bookable: product,
          quantity: 1,
          price_cents: 10000,
          taxable: false
        )

        booking.calculate_total_price

        # Only taxable item should be taxed
        taxable_item.calculate_tax
        expect(taxable_item.tax_amount_cents).to be > 0

        non_taxable_item.calculate_tax
        expect(non_taxable_item.tax_amount_cents.to_i).to eq(0)
      end
    end
  end

  describe 'Tax Overrides' do
    let(:booking) do
      create(:booking,
        company: company,
        start_date: 3.days.from_now,
        end_date: 7.days.from_now,
        subtotal_cents: 100000
      )
    end

    it 'allows manual tax override' do
      override_amount = Money.new(5000, 'USD')

      booking.override_tax!(
        amount: override_amount,
        reason: 'Special discount - reduced tax',
        user: user
      )

      expect(booking.reload.tax_override?).to be true
      expect(booking.tax_override_amount_cents).to eq(5000)
      expect(booking.tax_override_reason).to eq('Special discount - reduced tax')
      expect(booking.tax_override_by).to eq(user)
    end

    it 'uses override amount instead of calculated tax' do
      booking.override_tax!(
        amount: Money.new(1000, 'USD'),
        reason: 'Manual override',
        user: user
      )

      expect(booking.tax_total_cents).to eq(1000)
    end
  end

  describe 'Reverse Charge VAT (EU B2B)' do
    let(:eu_location) { create(:location, company: company, country: 'DE') }
    let(:booking) do
      create(:booking,
        company: company,
        venue_location: eu_location,
        client: client
      )
    end

    context 'when conditions are met' do
      before do
        # Mock business entity with VAT number
        business_entity = double('BusinessEntity', tax_id: 'FR12345678901')
        allow(client).to receive(:business_entities).and_return([business_entity])
      end

      it 'applies reverse charge for cross-border EU transactions' do
        result = booking.apply_reverse_charge?

        expect(result).to be true
      end
    end

    context 'when conditions are not met' do
      it 'does not apply reverse charge for non-EU countries' do
        booking.venue_location.update(country: 'US')

        expect(booking.apply_reverse_charge?).to be false
      end

      it 'does not apply reverse charge without VAT number' do
        allow(client).to receive(:business_entities).and_return([])

        expect(booking.apply_reverse_charge?).to be false
      end
    end
  end

  describe 'Tax Breakdown Report' do
    let(:tax_rate) do
      create(:tax_rate,
        company: company,
        name: 'Sales Tax',
        rate: 0.10,
        active: true
      )
    end

    let(:booking) do
      create(:booking,
        company: company,
        default_tax_rate: tax_rate,
        start_date: 3.days.from_now,
        end_date: 7.days.from_now
      )
    end

    before do
      create(:booking_line_item,
        booking: booking,
        bookable: product,
        quantity: 1,
        price_cents: 10000,
        tax_rate: tax_rate,
        taxable: true
      )
      booking.calculate_total_price
    end

    it 'provides detailed tax breakdown' do
      breakdown = booking.tax_breakdown

      expect(breakdown).to include(
        :subtotal, :tax_total, :grand_total,
        :tax_exempt, :tax_override, :line_items
      )
    end

    it 'includes line item tax details' do
      breakdown = booking.tax_breakdown
      line_item_breakdown = breakdown[:line_items].first

      expect(line_item_breakdown).to include(
        :bookable, :line_total, :tax_amount, :tax_rate
      )
    end

    it 'shows tax exempt status in breakdown' do
      booking.mark_tax_exempt!(reason: 'Test')
      breakdown = booking.tax_breakdown

      expect(breakdown[:tax_exempt]).to be true
      expect(breakdown[:tax_total].cents).to eq(0)
    end

    it 'shows tax override status in breakdown' do
      booking.override_tax!(
        amount: Money.new(1000, 'USD'),
        reason: 'Test',
        user: user
      )
      breakdown = booking.tax_breakdown

      expect(breakdown[:tax_override]).to be true
    end
  end

  describe 'Multi-Currency Tax Calculations' do
    let(:eur_tax_rate) do
      create(:tax_rate,
        company: company,
        name: 'EU VAT',
        rate: 0.20,
        country: 'DE',
        active: true
      )
    end

    let(:booking) do
      create(:booking,
        company: company,
        default_tax_rate: eur_tax_rate,
        total_price_currency: 'EUR'
      )
    end

    let!(:line_item) do
      create(:booking_line_item,
        booking: booking,
        bookable: product,
        quantity: 1,
        price_cents: 10000,
        price_currency: 'EUR',
        tax_rate: eur_tax_rate,
        taxable: true
      )
    end

    it 'calculates tax in correct currency' do
      booking.calculate_total_price

      expect(booking.tax_total_currency).to eq('EUR')
      expect(booking.grand_total_currency).to eq('EUR')
    end

    it 'maintains currency consistency' do
      booking.calculate_total_price

      expect(booking.subtotal_currency).to eq('EUR')
      expect(booking.tax_total_currency).to eq('EUR')
      expect(booking.grand_total_currency).to eq('EUR')
    end
  end

  describe 'Tax Recalculation on Changes' do
    let(:tax_rate) do
      create(:tax_rate,
        company: company,
        rate: 0.10,
        active: true
      )
    end

    let(:booking) do
      create(:booking,
        company: company,
        default_tax_rate: tax_rate
      )
    end

    it 'recalculates tax when line items are added' do
      booking.calculate_total_price
      original_tax = booking.tax_total_cents

      create(:booking_line_item,
        booking: booking,
        bookable: product,
        quantity: 1,
        price_cents: 10000,
        tax_rate: tax_rate,
        taxable: true
      )

      booking.calculate_total_price

      expect(booking.tax_total_cents).to be > original_tax
    end

    it 'recalculates tax when line item quantity changes' do
      line_item = create(:booking_line_item,
        booking: booking,
        bookable: product,
        quantity: 1,
        price_cents: 10000,
        tax_rate: tax_rate,
        taxable: true
      )

      booking.calculate_total_price
      original_tax = booking.tax_total_cents

      line_item.update(quantity: 2)
      booking.calculate_total_price

      expect(booking.tax_total_cents).to eq(original_tax * 2)
    end
  end
end
