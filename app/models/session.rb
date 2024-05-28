class Session < ApplicationRecord
  COOKIE_KEY = :session_id

  belongs_to :user
end
