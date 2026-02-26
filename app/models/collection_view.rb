class CollectionView < ApplicationRecord
  # Associations
  belongs_to :product_collection, counter_cache: :views_count
  belongs_to :user, optional: true

  # Validations
  validates :session_id, presence: true
  validates :viewed_at, presence: true

  # Scopes
  scope :recent, -> { order(viewed_at: :desc) }
  scope :last_24_hours, -> { where('viewed_at >= ?', 24.hours.ago) }
  scope :last_7_days, -> { where('viewed_at >= ?', 7.days.ago) }
  scope :last_30_days, -> { where('viewed_at >= ?', 30.days.ago) }
  scope :last_90_days, -> { where('viewed_at >= ?', 90.days.ago) }
  scope :by_session, ->(session_id) { where(session_id: session_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :unique_sessions, -> { select(:session_id).distinct }
  scope :with_referrer, -> { where.not(referrer: nil) }

  # Class Methods

  def self.unique_views_count
    distinct.count(:session_id)
  end

  def self.conversion_rate
    return 0 if count.zero?

    collection_ids = pluck(:product_collection_id).uniq
    product_ids = ProductCollection.where(id: collection_ids).flat_map(&:product_ids)

    bookings_count = Booking.joins(booking_line_items: :product)
                           .where(booking_line_items: { bookable_type: 'Product', bookable_id: product_ids })
                           .distinct.count

    (bookings_count.to_f / count * 100).round(2)
  end

  def self.top_referrers(limit = 10)
    where.not(referrer: nil)
      .group(:referrer)
      .order('count_id DESC')
      .limit(limit)
      .count(:id)
  end

  def self.by_hour_of_day
    group("EXTRACT(HOUR FROM viewed_at)").count
  end

  def self.by_day_of_week
    group("EXTRACT(DOW FROM viewed_at)").count
  end

  def self.views_over_time(period = 'day')
    case period
    when 'hour'
      group_by_hour(:viewed_at).count
    when 'day'
      group_by_day(:viewed_at).count
    when 'week'
      group_by_week(:viewed_at).count
    when 'month'
      group_by_month(:viewed_at).count
    else
      group_by_day(:viewed_at).count
    end
  end

  # Instance Methods

  def anonymous?
    user_id.nil?
  end

  def authenticated?
    user_id.present?
  end

  def from_referrer?
    referrer.present?
  end

  def referrer_domain
    return nil unless referrer
    URI.parse(referrer).host rescue nil
  end

  def viewing_duration_seconds
    return nil unless session_id

    next_view = CollectionView.where(session_id: session_id)
                              .where('viewed_at > ?', viewed_at)
                              .order(viewed_at: :asc)
                              .first

    return nil unless next_view

    (next_view.viewed_at - viewed_at).to_i
  end
end
