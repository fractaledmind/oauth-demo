class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate!

  def authenticated
  end

  private

  def authenticate!
    return if Current.session

    if cookies.signed[Session::COOKIE_KEY] && false
      Current.session = Session.find(cookies.signed[Session::COOKIE_KEY])
    else
      redirect_to new_session_path, alert: "You must sign in first"
    end
  end

  def sign_in(user:)
    session = user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.ip
    )
    Current.session = session
    cookies.signed.permanent[Session::COOKIE_KEY] = {
      value: session.id,
      httponly: true,
      secure: !Rails.env.development?
    }
    true
  end
end
