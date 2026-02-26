class ProductCollection < ApplicationRecord
  # Associations
  has_many :product_collection_items, -> { order(position: :asc) }, dependent: :destroy
  has_many :products, through: :product_collection_items
  has_many :collection_views, dependent: :destroy
  has_one_attached :featured_image
  has_one_attached :banner_image

  # Hierarchy
  belongs_to :parent_collection, class_name: 'ProductCollection', foreign_key: 'parent_collection_id', optional: true
  has_many :subcollections, class_name: 'ProductCollection', foreign_key: 'parent_collection_id', dependent: :destroy

  # Enums
  enum :visibility, {
    draft: 0,
    public_visible: 1,
    private_visible: 2,
    members_only: 3
  }

  enum :collection_type, {
    category: 0,
    featured: 1,
    seasonal: 2,
    event_type: 3,
    brand: 4,
    custom: 5,
    smart: 6
  }

  enum :display_template, {
    grid: 0,
    list: 1,
    masonry: 2,
    carousel: 3
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validate :prevent_circular_hierarchy
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where(active: true) }
  scope :public_collections, -> { where(visibility: :public_visible, active: true) }
  scope :featured_collections, -> { where(featured: true, active: true).order(position: :asc) }
  scope :root_collections, -> { where(parent_collection_id: nil) }
  scope :by_type, ->(type) { where(collection_type: type) }
  scope :dynamic, -> { where(is_dynamic: true) }
  scope :static, -> { where(is_dynamic: false) }
  scope :current, -> { where('start_date IS NULL OR start_date <= ?', Date.today).where('end_date IS NULL OR end_date >= ?', Date.today) }
  scope :expired, -> { where('end_date < ?', Date.today) }
  scope :upcoming, -> { where('start_date > ?', Date.today) }

  # Callbacks
  before_validation :generate_slug, on: :create
  before_validation :set_defaults
  after_save :update_product_count_cache, if: :saved_change_to_active?
  after_create :refresh_dynamic_products, if: :is_dynamic?

  # Instance Methods

  def breadcrumb_path
    ancestors = self.ancestors
    ancestors << self
    ancestors.map(&:name).join(' > ')
  end

  def url_path
    ancestors = self.ancestors
    ancestors << self
    '/collections/' + ancestors.map(&:slug).join('/')
  end

  def ancestors
    return [] unless parent_collection_id

    result = []
    current = parent_collection
    while current
      result.unshift(current)
      current = current.parent_collection
    end
    result
  end

  def descendants
    subs = subcollections.to_a
    subs + subs.flat_map(&:descendants)
  end

  def root?
    parent_collection_id.nil?
  end

  def leaf?
    subcollections.empty?
  end

  def depth
    ancestors.count
  end

  def siblings
    if parent_collection_id
      parent_collection.subcollections.where.not(id: id)
    else
      ProductCollection.root_collections.where.not(id: id)
    end
  end

  def add_product(product, position: nil, featured: false, notes: nil)
    product_collection_items.create!(
      product: product,
      position: position || next_position,
      featured: featured,
      notes: notes
    )
    update_product_count_cache
  end

  def remove_product(product)
    product_collection_items.find_by(product: product)&.destroy
    update_product_count_cache
  end

  def has_product?(product)
    products.exists?(product.id)
  end

  def featured_products(limit = 4)
    products.joins(:product_collection_items)
            .where(product_collection_items: { product_collection_id: id, featured: true })
            .limit(limit)
  end

  def active?
    return false unless active
    return false if start_date && start_date > Date.today
    return false if end_date && end_date < Date.today
    true
  end

  def current?
    active? && (start_date.nil? || start_date <= Date.today) && (end_date.nil? || end_date >= Date.today)
  end

  def expired?
    end_date.present? && end_date < Date.today
  end

  def upcoming?
    start_date.present? && start_date > Date.today
  end

  def days_until_start
    return nil unless start_date
    (start_date - Date.today).to_i
  end

  def days_until_end
    return nil unless end_date
    (end_date - Date.today).to_i
  end

  # Dynamic Collection Methods

  def dynamic?
    is_dynamic? && rules.present?
  end

  def refresh_dynamic_products
    return unless dynamic?

    matching_products = apply_rules

    transaction do
      # Clear existing items
      product_collection_items.destroy_all

      # Add matching products
      matching_products.each_with_index do |product, index|
        add_product(product, position: index)
      end
    end
  end

  def apply_rules
    return Product.none unless dynamic? && rules['conditions'].present?

    query = Product.active
    conditions = rules['conditions']
    match_type = rules['match'] || 'all'

    if match_type == 'all'
      conditions.each do |condition|
        query = apply_condition(query, condition)
      end
    else
      # 'any' logic - OR conditions
      queries = conditions.map { |condition| apply_condition(Product.active, condition) }
      query = queries.reduce { |combined, q| combined.or(q) }
    end

    # Apply sorting if specified
    if rules['sort_by']
      query = apply_sorting(query, rules['sort_by'], rules['sort_order'])
    end

    # Apply limit if specified
    query = query.limit(rules['limit']) if rules['limit']

    query
  end

  def apply_condition(query, condition)
    field = condition['field']
    operator = condition['operator']
    value = condition['value']

    case field
    when 'category'
      apply_category_condition(query, operator, value)
    when 'tags'
      apply_tags_condition(query, operator, value)
    when 'daily_price_cents'
      apply_price_condition(query, operator, value)
    when 'created_at'
      apply_date_condition(query, operator, value, 'created_at')
    when 'popularity_score'
      apply_number_condition(query, operator, value, 'popularity_score')
    when 'manufacturer_id'
      query.where(manufacturer_id: value)
    when 'product_type_id'
      query.where(product_type_id: value)
    else
      query
    end
  end

  def apply_category_condition(query, operator, value)
    case operator
    when 'equals' then query.where(category: value)
    when 'not_equals' then query.where.not(category: value)
    when 'contains' then query.where('category ILIKE ?', "%#{value}%")
    else query
    end
  end

  def apply_tags_condition(query, operator, value)
    case operator
    when 'contains' then query.where('? = ANY(tags)', value)
    when 'not_contains' then query.where.not('? = ANY(tags)', value)
    else query
    end
  end

  def apply_price_condition(query, operator, value)
    apply_number_condition(query, operator, value, 'daily_price_cents')
  end

  def apply_number_condition(query, operator, value, field)
    case operator
    when 'equals' then query.where(field => value)
    when 'not_equals' then query.where.not(field => value)
    when 'greater_than' then query.where("#{field} > ?", value)
    when 'less_than' then query.where("#{field} < ?", value)
    when 'greater_than_or_equal' then query.where("#{field} >= ?", value)
    when 'less_than_or_equal' then query.where("#{field} <= ?", value)
    else query
    end
  end

  def apply_date_condition(query, operator, value, field)
    date = Date.parse(value.to_s) rescue Date.today

    case operator
    when 'after' then query.where("#{field} > ?", date)
    when 'before' then query.where("#{field} < ?", date)
    when 'last_days' then query.where("#{field} >= ?", value.to_i.days.ago)
    else query
    end
  end

  def apply_sorting(query, sort_by, sort_order = 'asc')
    order_dir = sort_order == 'desc' ? :desc : :asc
    query.order(sort_by => order_dir)
  end

  # Analytics Methods

  def views_count
    collection_views.count
  end

  def unique_views_count
    collection_views.distinct.count(:session_id)
  end

  def views_last_30_days
    collection_views.where('viewed_at >= ?', 30.days.ago).count
  end

  def conversion_rate
    return 0 if views_count.zero?

    bookings_count = Booking.joins(booking_line_items: :product)
                           .where(booking_line_items: { bookable_type: 'Product', bookable_id: product_ids })
                           .distinct.count

    (bookings_count.to_f / views_count * 100).round(2)
  end

  def total_revenue
    Booking.joins(booking_line_items: :product)
          .where(booking_line_items: { bookable_type: 'Product', bookable_id: product_ids })
          .sum(:total_price_cents)
  end

  def popular_products(limit = 5)
    products.order(popularity_score: :desc).limit(limit)
  end

  def record_view!(session_id:, ip_address: nil, user_agent: nil, referrer: nil, user: nil)
    collection_views.create!(
      viewed_at: Time.current,
      session_id: session_id,
      ip_address: ip_address,
      user_agent: user_agent,
      referrer: referrer,
      user: user
    )
  end

  private

  def generate_slug
    return if slug.present?
    base_slug = name.parameterize
    candidate = base_slug
    counter = 1

    while ProductCollection.exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate
  end

  def set_defaults
    self.active = true if active.nil?
    self.featured = false if featured.nil?
    self.visibility ||= :public_visible
    self.collection_type ||= :category
    self.display_template ||= :grid
    self.is_dynamic = false if is_dynamic.nil?
    self.rules ||= {}
    self.product_count ||= 0
  end

  def next_position
    max_pos = product_collection_items.maximum(:position) || 0
    max_pos + 1
  end

  def update_product_count_cache
    update_column(:product_count, products.count)
  end

  def prevent_circular_hierarchy
    return unless parent_collection_id

    if parent_collection_id == id
      errors.add(:parent_collection_id, "cannot be itself")
      return
    end

    # Check if parent is a descendant
    if descendants.map(&:id).include?(parent_collection_id)
      errors.add(:parent_collection_id, "would create circular hierarchy")
    end
  end

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
