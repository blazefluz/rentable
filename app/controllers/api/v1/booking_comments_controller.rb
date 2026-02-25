# app/controllers/api/v1/booking_comments_controller.rb
module Api
  module V1
    class BookingCommentsController < ApplicationController
      before_action :set_booking
      before_action :set_comment, only: [:destroy]

      # GET /api/v1/bookings/:booking_id/comments
      def index
        @comments = @booking.booking_comments
                           .active
                           .includes(:user)
                           .recent_first

        render json: {
          comments: @comments.map { |c| comment_json(c) },
          count: @comments.count
        }
      end

      # POST /api/v1/bookings/:booking_id/comments
      def create
        @comment = @booking.booking_comments.new(comment_params)
        @comment.user = current_user # Assuming you have authentication

        if @comment.save
          render json: {
            comment: comment_json(@comment),
            message: "Comment added successfully"
          }, status: :created
        else
          render json: {
            errors: @comment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bookings/:booking_id/comments/:id
      def destroy
        @comment.soft_delete!
        render json: {
          message: "Comment deleted successfully"
        }
      end

      private

      def set_booking
        @booking = Booking.find(params[:booking_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Booking not found" }, status: :not_found
      end

      def set_comment
        @comment = @booking.booking_comments.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Comment not found" }, status: :not_found
      end

      def comment_params
        params.require(:comment).permit(:content)
      end

      def comment_json(comment)
        {
          id: comment.id,
          content: comment.content,
          user: {
            id: comment.user_id,
            name: comment.user.name,
            email: comment.user.email
          },
          created_at: comment.created_at,
          updated_at: comment.updated_at
        }
      end

      # Stub for current_user - replace with your authentication logic
      def current_user
        # For now, return the first user (admin)
        # In production, this should come from your authentication system
        User.first
      end
    end
  end
end
