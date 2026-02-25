class CommentUpvote < ApplicationRecord
  belongs_to :comment, counter_cache: :upvotes_count
  belongs_to :user

  validates :user_id, uniqueness: { scope: :comment_id, message: 'has already upvoted this comment' }
end
