class BucketService
  attr_accessor :bucket

  def initialize(bucket)
    @bucket = bucket
  end

  def save_image!(filename:)
    image = bucket.images.create(filename: filename)
    unless image.valid?
      GcsManagementService.new(bucket.id).delete_file(filename: filename)
    end

    image
  end
end
