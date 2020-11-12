require 'spec_helper'
include DataHelpers

describe BucketService do
  let(:user) { User.create(USER_DATA) }
  let(:bucket) { user.create_bucket }
  let(:filename) { 'test_filename' }
  let(:image) { bucket.images.create(filename: filename) }
  let(:gcs_service) { GcsManagementService.new(bucket.id) }
  subject { described_class.new(bucket) }

  describe '#save_image!' do
    before do
      allow(GcsManagementService).to receive(:new)
        .with(bucket.id).and_return(gcs_service)
      allow(bucket.images).to receive(:create)
        .with(filename: filename).and_return(image)
    end

    context 'when an image saves to a bucket' do
      before do
        allow(image).to receive(:valid?).and_return(true)
      end

      it 'saves an image to a bucket' do
        image = subject.save_image!(filename: filename)
        expect(gcs_service).to_not receive(:delete_file)
        expect(image.filename).to eq(filename)
      end
    end

    context 'when an image fails to save to a bucket' do
      before do
        allow(image).to receive(:valid?).and_return(false)
        allow(gcs_service).to receive(:delete_file).with(filename: filename).and_return(true)
        # fake image errors
        image.errors.add(:base)
      end

      it 'calls GcsManagementService to delete the file from the bucket' do
        expect(gcs_service).to receive(:delete_file).with(filename: filename)
        image = subject.save_image!(filename: filename)
        expect(image.errors).to_not be_blank
        expect(image.filename).to eq(filename)
      end
    end
  end
end
