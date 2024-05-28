class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
