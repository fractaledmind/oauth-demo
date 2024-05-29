class User::ConnectedAccount < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :provider_identifier, presence: true, uniqueness: { scope: :provider }
  validates :access_token, presence: true

  # encrypts :access_token
end
