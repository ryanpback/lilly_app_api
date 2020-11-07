class Bucket < ApplicationRecord
  validates :user_id, presence: true
end
