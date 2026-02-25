require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST /api/v1/auth/login' do
    context 'with valid credentials' do
      it 'returns a JWT token' do
        post '/api/v1/auth/login', params: {
          email: user.email,
          password: 'password123'
        }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to have_key('token')
        expect(json).to have_key('user')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized' do
        post '/api/v1/auth/login', params: {
          email: user.email,
          password: 'wrong_password'
        }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with non-existent user' do
      it 'returns unauthorized' do
        post '/api/v1/auth/login', params: {
          email: 'nonexistent@example.com',
          password: 'password'
        }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/auth/register' do
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          name: 'New User'
        }
      }
    end

    it 'creates a new user' do
      expect {
        post '/api/v1/auth/register', params: valid_params
      }.to change(User, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns error for invalid params' do
      post '/api/v1/auth/register', params: {
        user: { email: 'invalid', password: '123' }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/auth/me' do
    context 'with valid token' do
      it 'returns current user' do
        token = user.generate_jwt
        get '/api/v1/auth/me', headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['user']['id']).to eq(user.id)
      end
    end

    context 'without token' do
      it 'returns unauthorized' do
        get '/api/v1/auth/me'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
