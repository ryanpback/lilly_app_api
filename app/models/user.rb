class User < ApplicationRecord
  has_one :bucket, dependent: :destroy
  has_many :images, through: :bucket

  has_secure_password

  validates_presence_of :first_name, :last_name
  validates :username, presence: true, uniqueness: true
  validates :email,
            presence:   true,
            uniqueness: true,
            format:     {
              with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i,
              on:   :create,
            }
  validates :password, presence: true, length: 10..30

  def user_image_by_id(image_id)
    images.where(id: image_id)
          .select('images.id, buckets.id as bucket_id, images.filename')
          .first
  end
end
