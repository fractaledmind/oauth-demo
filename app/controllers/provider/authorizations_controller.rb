class Provider::AuthorizationsController < ApplicationController
  SCOPE = "openid profile email".freeze
  ACCESS_TOKEN_URL = "http://localhost:3001/provider/oauth/access_token".freeze
  USER_INFO_URL = "http://localhost:3001/provider/api/user_info".freeze

  skip_before_action :authenticate!, only: [ :create, :show ]

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

    # 1. existing user with existing connected account signs in
    if (connected_account = User::ConnectedAccount.find_by(provider: "provider", provider_identifier: user_info.id))
      connected_account.update!(
        access_token: access_credentials.access_token,
        auth: access_credentials.as_json["table"]
      )
      sign_in(user: connected_account.user)
      redirect_to root_path, notice: "Signed in with Provider"
    # 2. existing user connects a new connected account
    elsif Current.user.present?
      Current.user.connected_accounts.create!(
        provider: "provider",
        provider_identifier: user_info.id,
        access_token: access_credentials.access_token,
        auth: access_credentials.as_json["table"]
      )
      sign_in(user: Current.user)
      redirect_to root_path, notice: "Connected Provider account"
    # 3. new user signs up with connected account
    else
      user = User.new(email: user_info.email)
      user.connected_accounts.build(
        provider: "provider",
        provider_identifier: user_info.id,
        access_token: access_credentials.access_token,
        auth: access_credentials.as_json["table"]
      )
      if user.save
        sign_in(user: user)
        redirect_to root_path, notice: "Signed up with Provider"
      else
        redirect_to new_session_path, alert: "Authentication with Provider failed: #{user.errors.full_messages.to_sentence}"
      end
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
