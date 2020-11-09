class User < ApplicationRecord
  has_one :bucket, dependent: :destroy
  has_many :images, through: :bucket

  has_secure_password

  validates_presence_of :first_name, :last_name
  validates :username, presence: true, uniqueness: true
  validates :email,
    presence: true,
    uniqueness: true,
    format: {
      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
      on: :create
    }
    validates :password, presence: true, length: 10..30
end
