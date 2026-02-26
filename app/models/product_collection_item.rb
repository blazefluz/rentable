class ProductCollectionItem < ApplicationRecord
  # Associations
  belongs_to :product_collection, counter_cache: :product_count
  belongs_to :product
  belongs_to :added_by, class_name: 'User', foreign_key: 'added_by_id', optional: true

  # Validations
  validates :product_id, uniqueness: { scope: :product_collection_id, message: "is already in this collection" }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Scopes
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(position: :asc) }
  scope :recent, -> { order(added_at: :desc) }

  # Callbacks
  before_validation :set_position, on: :create, if: -> { position.nil? }
  before_validation :set_added_at, on: :create
  after_destroy :reorder_positions

  # Instance Methods

  def move_to_position(new_position)
    return if new_position == position

    transaction do
      if new_position > position
        # Moving down - shift items up
        product_collection.product_collection_items
          .where('position > ? AND position <= ?', position, new_position)
          .update_all('position = position - 1')
      else
        # Moving up - shift items down
        product_collection.product_collection_items
          .where('position >= ? AND position < ?', new_position, position)
          .update_all('position = position + 1')
      end

      update!(position: new_position)
    end
  end

  def move_up
    return if first?
    previous_item = product_collection.product_collection_items
                      .where('position < ?', position)
                      .order(position: :desc)
                      .first
    return unless previous_item

    swap_positions_with(previous_item)
  end

  def move_down
    return if last?
    next_item = product_collection.product_collection_items
                  .where('position > ?', position)
                  .order(position: :asc)
                  .first
    return unless next_item

    swap_positions_with(next_item)
  end

  def first?
    position == 1 || position == product_collection.product_collection_items.minimum(:position)
  end

  def last?
    position == product_collection.product_collection_items.maximum(:position)
  end

  def mark_as_featured!
    update!(featured: true)
  end

  def unmark_as_featured!
    update!(featured: false)
  end

  private

  def set_position
    max_position = product_collection.product_collection_items.maximum(:position) || 0
    self.position = max_position + 1
  end

  def set_added_at
    self.added_at ||= Time.current
  end

  def swap_positions_with(other_item)
    transaction do
      temp_position = position
      update!(position: other_item.position)
      other_item.update!(position: temp_position)
    end
  end

  def reorder_positions
    product_collection.product_collection_items.ordered.each_with_index do |item, index|
      item.update_column(:position, index + 1) if item.position != index + 1
    end
  end
end
