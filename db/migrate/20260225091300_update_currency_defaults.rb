class UpdateCurrencyDefaults < ActiveRecord::Migration[8.1]
  def up
    # Update existing NGN records to USD
    execute "UPDATE products SET daily_price_currency = 'USD' WHERE daily_price_currency = 'NGN'"
    execute "UPDATE kits SET daily_price_currency = 'USD' WHERE daily_price_currency = 'NGN'"
    execute "UPDATE bookings SET total_price_currency = 'USD' WHERE total_price_currency = 'NGN'"
    execute "UPDATE booking_line_items SET price_currency = 'USD' WHERE price_currency = 'NGN'"

    # Change default values
    change_column_default :products, :daily_price_currency, from: "NGN", to: "USD"
    change_column_default :kits, :daily_price_currency, from: "NGN", to: "USD"
    change_column_default :bookings, :total_price_currency, from: "NGN", to: "USD"
    change_column_default :booking_line_items, :price_currency, from: "NGN", to: "USD"
  end

  def down
    # Rollback if needed
    change_column_default :products, :daily_price_currency, from: "USD", to: "NGN"
    change_column_default :kits, :daily_price_currency, from: "USD", to: "NGN"
    change_column_default :bookings, :total_price_currency, from: "USD", to: "NGN"
    change_column_default :booking_line_items, :price_currency, from: "USD", to: "NGN"
  end
end
