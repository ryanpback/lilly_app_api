class ImageValidator
  IMAGE_UPLOAD_NAME = 'lilly_app_upload'.freeze
  ALLOWED_IMAGE_TYPES = %w(
    image/gif
    image/jpeg
    image/jpg
    image/png
    image/heic
    video/quicktime
  ).freeze

  attr_accessor :image, :error, :status

  def initialize(params)
    @image = params[IMAGE_UPLOAD_NAME]
  end

  def self.validate!(params:)
    new(params).determine_validity
  end

  def determine_validity
    unless file_present?
      set_file_not_present_error
      return self
    end

    set_file_incorrect_type unless valid_file_type?
    self
  end

  def file_present?
    image.present?
  end

  private

  def valid_file_type?
    file_type =
      IO.popen(
        ['file', '--brief', '--mime-type', image.path],
        in:  :close,
        err: :close,
      ) { |io| io.read.chomp }

    ALLOWED_IMAGE_TYPES.include?(file_type)
  end

  def allowed_file_types
    self.class::ALLOWED_IMAGE_TYPES.join(', ')
  end

  def set_file_incorrect_type
    self.error =
      "File type not allowed. Permitted file types: #{allowed_file_types}"
    self.status = :unsupported_media_type
  end

  def set_file_not_present_error
    self.error = 'No image present in upload.'
    self.status = :unprocessable_entity
  end
end
