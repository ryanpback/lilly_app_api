require 'spec_helper'
include DataHelpers

describe ImageService do
  let(:user) { User.create(USER_DATA) }
  let(:bucket) { user.create_bucket }
  let(:filename) { 'testfile' }
  let(:image) { bucket.images.create(filename: filename) }
  let(:gcs_service) { GcsManagementService.new(bucket.id) }
  let(:gcs_delete_file_status) { true }
  subject { described_class.new(image) }

  describe '.delete_image' do
    before do
      allow(described_class).to receive(:new)
        .with(image).and_return(subject)
    end

    context 'when called, it creates an Image Service instance' do
      it 'calls #delete' do
        expect(described_class).to receive(:new).with(image)
        expect(subject).to receive(:delete)
        described_class.delete_image(image: image)
      end
    end
  end

  describe '#delete' do
    before do
      allow(described_class).to receive(:new).with(image).and_return(subject)
      allow(GcsManagementService).to receive(:new)
        .and_return(gcs_service)
      allow(gcs_service).to receive(:delete_file)
        .with(filename: filename).and_return(gcs_delete_file_status)
    end

    context 'when GCS fails to delete file' do
      let(:gcs_delete_file_status) { false }

      it 'returns false' do
        expect(image).to receive(:bucket).and_return(bucket)
        expect(subject.delete).to be false
      end
    end

    context 'when GCS succeeds at deleting a file' do
      context 'when the image deletion succeeds' do
        before do
          allow(image).to receive(:destroyed?).and_return(true)
        end

        it 'returns false' do
          expect(image).to receive(:bucket).and_return(bucket)
          expect(image).to receive(:destroy)
          expect(image).to receive(:destroyed?)
          expect(subject.delete).to be true
        end
      end

      context 'when the image fails to be deleted' do
        before do
          allow(image).to receive(:destroyed?).and_return(false)
        end

        it 'returns false' do
          expect(image).to receive(:bucket).and_return(bucket)
          expect(image).to receive(:destroy)
          expect(image).to receive(:destroyed?)
          expect(subject.delete).to be false
        end
      end
    end
  end
end
