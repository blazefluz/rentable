class FinanceCacheService
  CACHE_TTL = 1.hour
  CACHE_PREFIX = 'finance'

  class << self
    # Revenue caching
    def cached_revenue(period: 'month', start_date: nil, end_date: nil)
      cache_key = "#{CACHE_PREFIX}:revenue:#{period}:#{start_date}:#{end_date}"
      fetch_from_cache(cache_key) do
        calculate_revenue(period, start_date, end_date)
      end
    end

    # Booking totals caching
    def cached_booking_total(booking_id)
      cache_key = "#{CACHE_PREFIX}:booking_total:#{booking_id}"
      fetch_from_cache(cache_key, ttl: 30.minutes) do
        calculate_booking_total(booking_id)
      end
    end

    # Client account value caching
    def cached_client_value(client_id)
      cache_key = "#{CACHE_PREFIX}:client_value:#{client_id}"
      fetch_from_cache(cache_key, ttl: 2.hours) do
        calculate_client_value(client_id)
      end
    end

    # Product utilization caching
    def cached_product_utilization(product_id, start_date, end_date)
      cache_key = "#{CACHE_PREFIX}:utilization:#{product_id}:#{start_date}:#{end_date}"
      fetch_from_cache(cache_key, ttl: 6.hours) do
        calculate_product_utilization(product_id, start_date, end_date)
      end
    end

    # Invalidation methods
    def invalidate_booking_cache(booking_id)
      invalidate_cache("#{CACHE_PREFIX}:booking_total:#{booking_id}")
      # Also invalidate client cache if booking has a client
      booking = Booking.find_by(id: booking_id)
      invalidate_client_cache(booking.client_id) if booking&.client_id
    end

    def invalidate_client_cache(client_id)
      invalidate_cache("#{CACHE_PREFIX}:client_value:#{client_id}")
    end

    def invalidate_revenue_cache
      invalidate_cache_pattern("#{CACHE_PREFIX}:revenue:*")
    end

    def clear_all_finance_cache
      invalidate_cache_pattern("#{CACHE_PREFIX}:*")
    end

    private

    def fetch_from_cache(key, ttl: CACHE_TTL)
      if use_redis?
        cached = REDIS_CLIENT.get(key)
        if cached
          JSON.parse(cached)
        else
          result = yield
          REDIS_CLIENT.setex(key, ttl.to_i, result.to_json)
          result
        end
      else
        Rails.cache.fetch(key, expires_in: ttl) { yield }
      end
    end

    def invalidate_cache(key)
      if use_redis?
        REDIS_CLIENT.del(key)
      else
        Rails.cache.delete(key)
      end
    end

    def invalidate_cache_pattern(pattern)
      if use_redis?
        keys = REDIS_CLIENT.keys(pattern)
        REDIS_CLIENT.del(*keys) if keys.any?
      else
        # Rails.cache doesn't support pattern deletion, so we clear everything
        Rails.cache.clear if Rails.env.development?
      end
    end

    def use_redis?
      defined?(REDIS_CLIENT) && REDIS_CLIENT.present?
    end

    # Calculation methods
    def calculate_revenue(period, start_date, end_date)
      bookings = Booking.where(status: [:confirmed, :completed])
      
      case period
      when 'day'
        bookings = bookings.where('created_at >= ?', 1.day.ago)
      when 'week'
        bookings = bookings.where('created_at >= ?', 1.week.ago)
      when 'month'
        bookings = bookings.where('created_at >= ?', 1.month.ago)
      when 'year'
        bookings = bookings.where('created_at >= ?', 1.year.ago)
      when 'custom'
        bookings = bookings.where(created_at: start_date..end_date) if start_date && end_date
      end

      {
        total_cents: bookings.sum(:total_price_cents),
        total_currency: bookings.first&.total_price_currency || 'USD',
        count: bookings.count,
        period: period,
        calculated_at: Time.current
      }
    end

    def calculate_booking_total(booking_id)
      booking = Booking.includes(:booking_line_items).find(booking_id)
      line_items_total = booking.booking_line_items.sum(:price_cents)
      
      {
        booking_id: booking_id,
        line_items_total_cents: line_items_total,
        total_price_cents: booking.total_price_cents,
        currency: booking.total_price_currency,
        calculated_at: Time.current
      }
    end

    def calculate_client_value(client_id)
      bookings = Booking.where(client_id: client_id, status: [:confirmed, :completed])
      
      {
        client_id: client_id,
        total_value_cents: bookings.sum(:total_price_cents),
        currency: bookings.first&.total_price_currency || 'USD',
        booking_count: bookings.count,
        average_booking_cents: bookings.count > 0 ? bookings.sum(:total_price_cents) / bookings.count : 0,
        calculated_at: Time.current
      }
    end

    def calculate_product_utilization(product_id, start_date, end_date)
      product = Product.find(product_id)
      bookings = BookingLineItem.joins(:booking)
                                 .where(bookable_id: product_id, bookable_type: 'Product')
                                 .where(bookings: { start_date: start_date..end_date, status: [:confirmed, :completed] })

      total_days = (end_date.to_date - start_date.to_date).to_i
      booked_days = bookings.sum(:days)
      
      {
        product_id: product_id,
        utilization_percentage: total_days > 0 ? (booked_days.to_f / total_days * 100).round(2) : 0,
        booked_days: booked_days,
        total_days: total_days,
        booking_count: bookings.count,
        calculated_at: Time.current
      }
    end
  end
end
