class Provider::AuthorizationsController < ApplicationController
  DISCOVERY_DOCUMENT_URL = "http://localhost:3001/provider/.well-known/openid-configuration".freeze

  skip_before_action :authenticate!, only: [ :create, :show ]

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    Rails.error.report(exception)
    redirect_to new_session_path, alert: "Authentication with Provider failed: invalid state token"
  end

  rescue_from ActionController::ParameterMissing do |exception|
    Rails.error.report(exception)
    redirect_to new_session_path, alert: "Authentication with Provider failed: invalid state token"
  end

  rescue_from JWT::DecodeError do |exception|
    Rails.error.report(exception)
    redirect_to new_session_path, alert: "Authentication with Provider failed: invalid JWT"
  end

  # POST /provider/authorization
  def create
    authorization_url = openid_client.authorize_url(redirect_uri: provider_authorization_url,
                                                    state: form_authenticity_token)
    redirect_to authorization_url, allow_other_host: true
  end

  # GET /provider/authorization
  def show
    verify_state!
    access_credentials = openid_client.fetch_tokens(code: params.fetch(:code), redirect_uri: provider_authorization_url)
    user_info = decode_and_verify_token(access_credentials.id_token)

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
  rescue ApplicationClient::Error => exception
    Rails.error.report(exception)
    msg = begin
      JSON.parse(exception.message).fetch("error_description", "Unknown error")
    rescue JSON::ParserError
      exception.message
    end
    redirect_to new_session_path, alert: "Authentication with Provider failed: #{msg}"
  end

  private

  def verify_state!
    state_token = params.fetch(:state)
    unless valid_authenticity_token?(session, state_token)
      raise ActionController::InvalidAuthenticityToken, "The state=#{state_token} token is inauthentic."
    end
  end

  def decode_and_verify_token(token)
    decode_options = {
      algorithm: "RS256",
      verify_expiration: true,
      verify_iat: true,
      verify_iss: true,
      iss: "http://localhost:3001",
      verify_aud: true,
      aud: Rails.application.credentials.provider.client_id,
      jwks: openid_client.json_web_key_set
    }

    user_info = JWT.decode(token, nil, true, decode_options).first
    OpenStruct.new(user_info)
  end

  def openid_client
    OpenIdClient.new(discovery_document_url: DISCOVERY_DOCUMENT_URL,
                     client_id: Rails.application.credentials.provider.client_id,
                     client_secret: Rails.application.credentials.provider.client_secret)
  end
end
