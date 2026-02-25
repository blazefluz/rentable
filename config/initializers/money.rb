# config/initializers/money.rb
MoneyRails.configure do |config|
  # Default currency - USD for global product
  config.default_currency = :usd

  # Rounding mode
  config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Locale backend for currency formatting
  config.locale_backend = :currency

  # Allow currency to be set from model attribute
  config.include_validations = true
end
