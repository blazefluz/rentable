# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < ApplicationController
      # Allow public access to login and register
      skip_before_action :authenticate_user!, only: [:login, :register]

      # Require authentication for protected endpoints (me, refresh)
      # This is now automatically enforced by ApplicationController

      # POST /api/v1/auth/register
      def register
        @user = User.new(user_params)
        @user.role = :customer # Default role

        if @user.save
          render json: {
            user: user_json(@user),
            token: @user.generate_jwt,
            message: "Registration successful"
          }, status: :created
        else
          render json: {
            errors: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        @user = User.find_by(email: params[:email])

        if @user&.authenticate(params[:password])
          render json: {
            user: user_json(@user),
            token: @user.generate_jwt,
            message: "Login successful"
          }
        else
          render json: {
            error: "Invalid email or password"
          }, status: :unauthorized
        end
      end

      # GET /api/v1/auth/me
      def me
        render json: {
          user: user_json(current_user)
        }
      end

      # POST /api/v1/auth/refresh
      def refresh
        render json: {
          token: current_user.generate_jwt,
          message: "Token refreshed"
        }
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :name)
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          api_token: user.api_token,
          created_at: user.created_at
        }
      end
    end
  end
end
