require 'spec_helper'
require 'google/cloud/storage'
include DataHelpers

describe GcsManagementService do
  let(:user) { User.create(USER_DATA) }
  let(:lilly_app_bucket) { user.create_bucket }
  let(:bucket_name) { lilly_app_bucket.id }
  let(:storage_client) { subject.storage_client }
  let(:filename) { 'test.png' }
  let(:path_to_file) do
    Rails.root.join "spec/support/files/#{filename}"
  end
  let(:uploaded_file) do
    Rack::Test::UploadedFile.new(path_to_file, 'image/png')
  end
  let(:gcs_file) do
    Google::Cloud::Storage::File.new_lazy(
      bucket_name,
      filename,
      storage_client.service,
    )
  end
  let(:gcs_bucket) do
    Google::Cloud::Storage::Bucket.new_lazy(
      bucket_name,
      storage_client.service,
    )
  end
  subject { described_class.new(bucket_name) }

  before do
    allow(described_class).to receive(:new)
      .and_return(subject)
    allow(subject).to receive(:bucket)
      .and_return(gcs_bucket)
  end

  describe '#upload_file' do
    before do
      allow(subject).to receive(:create_bucket)
        .and_return(gcs_bucket)
      allow(gcs_bucket).to receive(:create_file)
        .and_return(gcs_file)
    end

    context 'when the bucket doesn\'t exists in gcs' do
      before do
        allow(subject).to receive(:bucket_exists?)
          .and_return(false)
      end

      it 'creates a new bucket and returns filename' do
        expect(subject).to receive(:create_bucket)
        expect(subject.upload_file(file: uploaded_file)).to eq(filename)
      end
    end

    context 'when the bucket exists in gcs' do
      it 'doesn not create a new bucket and returns filename' do
        expect(subject).to_not receive(:create_bucket)
        expect(subject.upload_file(file: uploaded_file)).to eq(filename)
      end
    end
  end

  describe '#get_file' do
    before do
      allow(gcs_bucket).to receive(:file)
        .with("#{bucket_name}/#{filename}").and_return(gcs_file)
    end

    it 'returns a gcs file' do
      expect(gcs_bucket).to receive(:file)
        .with("#{bucket_name}/#{filename}")
      file = subject.get_file(filename: filename)
      expect(file).to eq(gcs_file)
    end
  end

  describe '#delete_file' do
    context 'when the gcs_file exists' do
      before do
        allow(subject).to receive(:get_file)
          .with(filename: filename).and_return(gcs_file)
        allow(gcs_file).to receive(:delete).and_return(true)
      end

      it 'returns true' do
        expect(subject).to receive(:get_file)
          .with(filename: filename)
        expect(gcs_file).to receive(:delete)
        deleted = subject.delete_file(filename: filename)
        expect(deleted).to be true
      end
    end

    context 'when the gcs_file doesn\'t exists' do
      before do
        allow(subject).to receive(:get_file)
          .with(filename: filename).and_return(nil)
      end

      it 'returns true' do
        expect(subject).to receive(:get_file)
          .with(filename: filename)
        deleted = subject.delete_file(filename: filename)
        expect(deleted).to be true
      end
    end
  end

  describe '#delete_bucket' do
    before do
      allow(gcs_bucket).to receive(:files)
        .and_return([gcs_file])
      allow(gcs_file).to receive(:delete).and_return(true)
    end

    context 'when a bucket is successfully delete' do
      before do
        allow(gcs_bucket).to receive(:delete)
          .and_return(true)
      end

      it 'returns true' do
        expect(gcs_bucket).to receive(:files)
        expect(gcs_file).to receive(:delete)
        expect(gcs_bucket).to receive(:delete)
        expect(subject.delete_bucket).to be true
      end
    end

    context 'when a bucket is not deleted successfully' do
      before do
        allow(gcs_bucket).to receive(:delete)
          .and_return(false)
      end

      it 'returns false' do
        expect(gcs_bucket).to receive(:files)
        expect(gcs_file).to receive(:delete)
        expect(gcs_bucket).to receive(:delete)
        expect(subject.delete_bucket).to be false
      end
    end
  end

  describe '#create_bucket' do
    context 'when a bucket is succesfully created' do
      before do
        allow(storage_client).to receive(:create_bucket)
          .and_return(gcs_bucket)
      end

      it 'returns a gcs storage bucket' do
        expect(subject.create_bucket).to eq(gcs_bucket)
      end
    end

    context 'when creating an already existing bucket' do
      let(:error_message) { 'bucket already exists' }

      before do
        allow(storage_client).to receive(:create_bucket)
          .and_raise(Google::Cloud::AlreadyExistsError, error_message)
      end

      it 'rescues a Google::Cloud::AlreadyExistsError and returns a BucketExistsError' do
        expect { subject.create_bucket }.to raise_exception(GcsManagementService::BucketExistsError, error_message)
      end
    end
  end
end
