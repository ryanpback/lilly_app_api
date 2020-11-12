class ImageService
  attr_reader :image

  def initialize(image)
    @image = image
  end

  def self.delete_image(image:)
    new(image).delete
  end

  def delete
    bucket = image.bucket
    image_deleted = GcsManagementService.new(bucket.id).delete_file(filename: image.filename)

    return false unless image_deleted

    image.destroy

    image.destroyed?
  end
end
