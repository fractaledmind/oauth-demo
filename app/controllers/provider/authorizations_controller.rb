class Provider::AuthorizationsController < ApplicationController
  SCOPE = "openid profile email".freeze

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
    # ...
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

  def verify_state!
    state_token = params.fetch(:state)
    unless valid_authenticity_token?(session, state_token)
      raise ActionController::InvalidAuthenticityToken, "The state=#{state_token} token is inauthentic."
    end
  end
end
