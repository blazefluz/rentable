# app/models/booking_template.rb
class BookingTemplate < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :client, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  # Enums
  enum :template_type, {
    standard: 0,           # Standard booking template
    equipment_package: 1,  # Pre-configured equipment package
    event_type: 2,         # Event-specific template (wedding, corporate, etc)
    client_specific: 3,    # Saved for specific recurring client
    quick_rental: 4        # Quick one-click rental templates
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :template_type, presence: true
  validates :booking_data, presence: true

  # Scopes
  scope :active, -> { where(deleted: false, archived: false) }
  scope :public_templates, -> { where(is_public: true, deleted: false) }
  scope :favorites, -> { where(favorite: true, deleted: false) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_type, ->(type) { where(template_type: type) if type.present? }
  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :popular, -> { where('usage_count > 0').order(usage_count: :desc) }
  scope :recently_used, -> { where.not(last_used_at: nil).order(last_used_at: :desc) }
  scope :search, ->(query) {
    if query.present?
      where("name ILIKE ? OR description ILIKE ? OR category ILIKE ? OR ? = ANY(tags)",
            "%#{query}%", "%#{query}%", "%#{query}%", query)
    end
  }

  # Create booking from template
  def create_booking(overrides = {})
    # Merge template data with overrides
    booking_attributes = booking_data.deep_symbolize_keys.merge(overrides.symbolize_keys)

    # Create the booking
    booking = Booking.new(booking_attributes)

    # Increment usage counter
    increment_usage!

    booking
  end

  # Create and save booking from template
  def create_booking!(overrides = {})
    booking = create_booking(overrides)
    booking.save!
    booking
  end

  # Preview booking without saving
  def preview_booking(overrides = {})
    create_booking(overrides)
  end

  # Create template from existing booking
  def self.create_from_booking(booking, attributes = {})
    template_data = {
      customer_name: booking.customer_name,
      customer_email: booking.customer_email,
      customer_phone: booking.customer_phone,
      notes: booking.notes,
      venue_location_id: booking.venue_location_id,
      client_id: booking.client_id,
      total_price_cents: booking.total_price_cents,
      total_price_currency: booking.total_price_currency,
      booking_line_items_attributes: booking.booking_line_items.map do |item|
        {
          bookable_type: item.bookable_type,
          bookable_id: item.bookable_id,
          quantity: item.quantity,
          price_cents: item.price_cents,
          price_currency: item.price_currency,
          discount_percent: item.discount_percent
        }
      end
    }

    create!(
      name: attributes[:name] || "Template from Booking ##{booking.reference_number}",
      description: attributes[:description],
      template_type: attributes[:template_type] || :standard,
      booking_data: template_data,
      client_id: booking.client_id,
      created_by: attributes[:created_by],
      category: attributes[:category],
      tags: attributes[:tags] || [],
      is_public: attributes[:is_public] || false,
      estimated_duration_days: booking.rental_days
    )
  end

  # Update template from booking
  def update_from_booking(booking)
    template_data = {
      customer_name: booking.customer_name,
      customer_email: booking.customer_email,
      customer_phone: booking.customer_phone,
      notes: booking.notes,
      venue_location_id: booking.venue_location_id,
      client_id: booking.client_id,
      booking_line_items_attributes: booking.booking_line_items.map do |item|
        {
          bookable_type: item.bookable_type,
          bookable_id: item.bookable_id,
          quantity: item.quantity,
          price_cents: item.price_cents,
          price_currency: item.price_currency,
          discount_percent: item.discount_percent
        }
      end
    }

    update!(
      booking_data: template_data,
      estimated_duration_days: booking.rental_days
    )
  end

  # Add tag to template
  def add_tag(tag)
    return if tags.include?(tag)
    self.tags = tags + [tag]
    save
  end

  # Remove tag from template
  def remove_tag(tag)
    self.tags = tags - [tag]
    save
  end

  # Toggle favorite
  def toggle_favorite!
    update!(favorite: !favorite)
  end

  # Increment usage counter
  def increment_usage!
    increment!(:usage_count)
    touch(:last_used_at)
  end

  # Archive template
  def archive!
    update!(archived: true)
  end

  # Unarchive template
  def unarchive!
    update!(archived: false)
  end

  # Soft delete
  def soft_delete!
    update!(deleted: true)
  end

  # Duplicate template
  def duplicate(new_name = nil)
    dup.tap do |template|
      template.name = new_name || "#{name} (Copy)"
      template.usage_count = 0
      template.last_used_at = nil
      template.favorite = false
      template.booking_data = booking_data.deep_dup
      template.save!
    end
  end

  # Get equipment list from template
  def equipment_list
    return [] unless booking_data.is_a?(Hash)

    line_items = booking_data.dig('booking_line_items_attributes') ||
                 booking_data.dig(:booking_line_items_attributes) || []

    line_items.map do |item|
      {
        type: item['bookable_type'] || item[:bookable_type],
        id: item['bookable_id'] || item[:bookable_id],
        quantity: item['quantity'] || item[:quantity],
        name: fetch_bookable_name(item)
      }
    end
  end

  # Get total estimated cost
  def estimated_cost
    return Money.new(0, 'USD') unless booking_data.is_a?(Hash)

    total_cents = booking_data['total_price_cents'] ||
                  booking_data[:total_price_cents] || 0
    currency = booking_data['total_price_currency'] ||
               booking_data[:total_price_currency] || 'USD'

    Money.new(total_cents, currency)
  end

  # Check if template is valid (all items still exist)
  def valid_template?
    equipment_list.all? do |item|
      klass = item[:type].constantize
      klass.exists?(item[:id])
    end
  rescue
    false
  end

  # Get missing items (items that no longer exist)
  def missing_items
    equipment_list.reject do |item|
      klass = item[:type].constantize
      klass.exists?(item[:id])
    end
  rescue
    []
  end

  private

  def fetch_bookable_name(item)
    bookable_type = item['bookable_type'] || item[:bookable_type]
    bookable_id = item['bookable_id'] || item[:bookable_id]

    return nil unless bookable_type && bookable_id

    klass = bookable_type.constantize
    bookable = klass.find_by(id: bookable_id)
    bookable&.name
  rescue
    nil
  end
end
