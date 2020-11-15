require 'spec_helper'

describe ImageValidator do
  let(:filename) { 'test.png' }
  let(:file_type) { 'image/png' }
  let(:path_to_file) do
    Rails.root.join "spec/support/files/#{filename}"
  end
  let(:uploaded_file) do
    Rack::Test::UploadedFile.new(path_to_file, file_type)
  end
  let(:params) { {} }
  subject { described_class.new(params) }
  let(:allowed_image_types) do
    %w(
      image/gif
      image/jpeg
      image/jpg
      image/png
      image/heic
      video/quicktime
    )
  end

  before do
    allow(params).to receive(:[])
      .with(described_class::IMAGE_UPLOAD_NAME)
      .and_return(uploaded_file)
    allow(described_class).to receive(:new)
      .and_return(subject)
  end

  describe 'ALLOWED_IMAGE_TYPES' do
    it 'allows specific file types' do
      expect(described_class::ALLOWED_IMAGE_TYPES).to eq(allowed_image_types)
    end
  end

  describe '.validate!' do
    it 'calls #determine_validity' do
      expect(described_class).to receive(:new).with(params)
      expect(subject).to receive(:determine_validity)
      described_class.validate!(params: params)
    end
  end

  describe '#determine_validity' do
    context 'when the image is valid' do
      it 'returns no errors when the file is present' do
        expect(subject.determine_validity.error).to be_nil
      end

      it 'returns no errors when the file type is valid' do
        expect(subject.determine_validity.error).to be_nil
      end
    end

    context 'when the image is invalid' do
      let(:filename) { 'invalid_file.txt' }
      let(:file_type) { 'text/plain' }

      context 'when params[upload_name] is nil' do
        before do
          allow(subject.image).to receive(:present?)
            .and_return(false)
        end

        it 'returns an error when the file is not present' do
          expect(subject.determine_validity.error).to match(/No image present in upload/)
        end
      end

      it 'returns an error when the file type is invalid' do
        expect(subject.determine_validity.error).to match(/File type not allowed/)
      end
    end
  end
end
