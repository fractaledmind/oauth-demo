class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :connected_accounts, class_name: "User::ConnectedAccount", dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
