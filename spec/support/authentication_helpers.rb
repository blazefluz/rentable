# spec/support/authentication_helpers.rb
module AuthenticationHelpers
  # Generate JWT token for a user
  def auth_token_for(user)
    user.generate_jwt
  end

  # Generate authorization header for a user
  def auth_headers_for(user)
    {
      'Authorization' => "Bearer #{auth_token_for(user)}",
      'Content-Type' => 'application/json'
    }
  end

  # Helper to make authenticated requests
  def authenticated_get(path, user:, params: {}, headers: {})
    get path, params: params, headers: auth_headers_for(user).merge(headers)
  end

  def authenticated_post(path, user:, params: {}, headers: {})
    post path, params: params.to_json, headers: auth_headers_for(user).merge(headers)
  end

  def authenticated_patch(path, user:, params: {}, headers: {})
    patch path, params: params.to_json, headers: auth_headers_for(user).merge(headers)
  end

  def authenticated_put(path, user:, params: {}, headers: {})
    put path, params: params.to_json, headers: auth_headers_for(user).merge(headers)
  end

  def authenticated_delete(path, user:, params: {}, headers: {})
    delete path, params: params, headers: auth_headers_for(user).merge(headers)
  end

  # Create a test user with authentication token
  def create_authenticated_user(role: :admin, company: nil)
    company ||= create(:company)
    user = create(:user, role: role, company: company)
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
