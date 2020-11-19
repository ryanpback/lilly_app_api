require 'google/cloud/storage'

class GcsManagementService
  class BucketExistsError < StandardError; end
  attr_reader :bucket_name, :storage_client, :bucket

  PROJECT_ID = Rails.application.credentials.gcs[:project_id].freeze
  CREDENTIALS_FILE = Rails.application.credentials.gcs[:path_to_config].freeze

  def initialize(bucket_id)
    @bucket_name = bucket_id
    @storage_client =
      Google::Cloud::Storage.new(
        project:     PROJECT_ID,
        credentials: CREDENTIALS_FILE,
      )
  end

  def upload_file(file:)
    create_bucket unless bucket_exists?

    uploaded_file = bucket.create_file(file.path, file.original_filename)
    uploaded_file.name
  end

  def get_file(filename:)
    bucket.file(filename)
  end

  def delete_file(filename:)
    file = get_file(filename: filename)
    return file.delete if file

    true
  end

  def delete_bucket
    bucket.files.each(&:delete)
    return true if bucket.delete

    false
  end

  def create_bucket
    storage_client.create_bucket(
      bucket_name,
      location:      'US-WEST2',
      storage_class: 'STANDARD',
    )
  rescue Google::Cloud::AlreadyExistsError => e
    raise BucketExistsError, e.message
  end

  def generate_signed_url(filename:)
    storage_expiry_time = 5 * 60 # 5 minutes
    storage_client.signed_url(bucket_name, filename, method: 'GET', expires: storage_expiry_time, version: :v4)
  end

  private

  def bucket
    @bucket ||= storage_client.bucket(bucket_name)
  end

  def bucket_exists?
    !!bucket
  end
end
