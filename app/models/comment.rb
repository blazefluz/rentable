class Comment < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  belongs_to :parent_comment, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: :parent_comment_id, dependent: :destroy
  has_many :comment_upvotes, dependent: :destroy
  has_many :upvoters, through: :comment_upvotes, source: :user

  # Validations
  validates :content, presence: true
  validates :user_id, presence: true

  # Scopes
  scope :active, -> { where(deleted: [false, nil]) }
  scope :top_level, -> { where(parent_comment_id: nil) }
  scope :replies_to, ->(comment) { where(parent_comment_id: comment.id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_upvoted, -> { order(upvotes_count: :desc) }

  # Counter cache
  after_create :increment_parent_replies_count
  after_destroy :decrement_parent_replies_count

  after_initialize :set_defaults

  # Check if user has upvoted
  def upvoted_by?(user)
    comment_upvotes.exists?(user: user)
  end

  # Toggle upvote
  def toggle_upvote(user)
    if upvoted_by?(user)
      comment_upvotes.find_by(user: user).destroy
      decrement!(:upvotes_count)
      false
    else
      comment_upvotes.create(user: user)
      increment!(:upvotes_count)
      true
    end
  end

  # Get reply tree
  def reply_tree
    replies.active.includes(:user, :replies)
  end

  # Check if this is a top-level comment
  def top_level?
    parent_comment_id.nil?
  end

  # Get the thread (all ancestors)
  def thread
    return [self] if top_level?
    parent_comment.thread + [self]
  end

  private

  def set_defaults
    self.deleted ||= false
    self.upvotes_count ||= 0
  end

  def increment_parent_replies_count
    parent_comment&.increment!(:replies_count) if respond_to?(:replies_count)
  end

  def decrement_parent_replies_count
    parent_comment&.decrement!(:replies_count) if respond_to?(:replies_count)
  end
end
