class Bucket < ApplicationRecord
  has_many :images, dependent: :destroy

  validates :user_id, presence: true
end
