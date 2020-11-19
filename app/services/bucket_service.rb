class BucketService
  attr_accessor :bucket

  def initialize(bucket)
    @bucket = bucket
  end

  def save_image!(filename:)
    image = bucket.images.create(filename: filename)
    GcsManagementService
      .new(bucket.id)
      .delete_file(filename: filename) unless image.valid?

    image
  end
end
