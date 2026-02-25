# config/initializers/money.rb
MoneyRails.configure do |config|
  # Default currency
  config.default_currency = :ngn

  # Rounding mode
  config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Locale backend for currency formatting
  config.locale_backend = :currency

  # Allow currency to be set from model attribute
  config.include_validations = true

  # Register currencies (NGN and USD)
  config.register_currency = {
    priority: 1,
    iso_code: "NGN",
    name: "Nigerian Naira",
    symbol: "₦",
    subunit: "Kobo",
    subunit_to_unit: 100,
    separator: ".",
    delimiter: ","
  }
end
