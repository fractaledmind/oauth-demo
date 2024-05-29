class Provider::AuthorizationsController < ApplicationController
  SCOPE = "openid profile email".freeze
  ACCESS_TOKEN_URL = "http://localhost:3001/provider/oauth/access_token".freeze
  USER_INFO_URL = "http://localhost:3001/provider/api/user_info".freeze

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    Rails.error.report(exception)
    redirect_to new_session_path, alert: "Authentication with Provider failed: invalid state token"
  end

  # POST /provider/authorization
  def create
    redirect_to authorize_url, allow_other_host: true
  end

  # GET /provider/authorization
  def show
    verify_state!
    access_credentials = request_access_credentials!
    user_info = request_user_info!(access_token: access_credentials.access_token)
    user = User.new(email: user_info.email)
    if user.save
      sign_in(user: user)
      redirect_to root_path
    else
    end
  end

  private

  def authorize_url
    uri = URI("http://localhost:3001/provider/authorize")
    uri.query = Rack::Utils.build_query({
      response_type: "code",
      client_id: Rails.application.credentials.provider.client_id,
      redirect_uri: provider_authorization_url,
      scope: SCOPE,
      state: form_authenticity_token
    })
    uri.to_s
  end

  def request_access_credentials!
    client = ApplicationClient.new
    response = client.post(ACCESS_TOKEN_URL, body: {
      client_id: Rails.application.credentials.provider.client_id,
      client_secret: Rails.application.credentials.provider.client_secret,
      code: params.fetch(:code),
      redirect_uri: provider_authorization_url
    })
    response.parsed_body
  end

  def request_user_info!(access_token:)
    client = ApplicationClient.new(token: access_token)
    response = client.get(USER_INFO_URL)
    response.parsed_body
  end

  def verify_state!
    state_token = params.fetch(:state)
    unless valid_authenticity_token?(session, state_token)
      raise ActionController::InvalidAuthenticityToken, "The state=#{state_token} token is inauthentic."
    end
  end
end