require 'google/cloud/storage'
require 'yaml/store'

class GcsManagementService
  class BucketExistsError < StandardError; end
  attr_reader :bucket_name, :storage_client, :bucket

  PROJECT_ID = Rails.application.credentials.gcs[:project_id].freeze
  CREDENTIALS_FILE = Rails.application.credentials.gcs[:path_to_config].freeze

  def initialize(bucket_id)
    @bucket_name = bucket_id
    @storage_client =
      Google::Cloud::Storage.new(
        project: PROJECT_ID,
        credentials: CREDENTIALS_FILE
      )
  end

  def upload_file(file:)
    create_bucket unless bucket_exists?

    uploaded_file = bucket.create_file(file.path, file.original_filename)
    uploaded_file.name
  end

  def get_file(filename:)
    file_path = "#{bucket_name}/#{filename}"
    bucket.file(file_path)
  end

  def delete_file(filename:)
    file = get_file(filename: filename)
    file.delete if file
  end

  def delete_bucket
    bucket.files.each { |f| f.delete }
    return true if bucket.delete
    false
  end

  private

  def bucket
    @bucket ||= storage_client.bucket(bucket_name)
  end

  def bucket_exists?
    !!bucket
  end

  def create_bucket
    storage_client.create_bucket(
      bucket_name,
      location: 'US-WEST2',
      storage_class: 'STANDARD'
    )
  rescue Google::Cloud::AlreadyExistsError => e
    raise BucketExistsError, e.message
  end
end
