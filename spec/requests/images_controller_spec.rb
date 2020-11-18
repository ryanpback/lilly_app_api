require 'spec_helper'
include DataHelpers

describe ImagesController, type: :request do
  let(:user) { User.create(USER_DATA) }
  let(:bucket) { user.create_bucket }
  let(:filename) { 'test.png' }
  let(:image) { bucket.images.create(filename: filename) }
  let(:token) do
    AuthorizationService.encode_token({ user_id: user.id })
  end
  let(:headers) { { 'Authorization': "Bearer #{token}" } }
  let(:path_to_file) do
    Rails.root.join "spec/support/files/#{filename}"
  end
  let(:uploaded_file) do
    fixture_file_upload(path_to_file, 'image/png', true)
  end
  let(:params) { { lilly_app_upload: uploaded_file } }
  let(:image_validator) { ImageValidator.new(params) }
  let(:gcs_service) { GcsManagementService.new(bucket.id) }
  let(:bucket_service) { BucketService.new(bucket) }

  before do
    allow(GcsManagementService).to receive(:new)
      .with(bucket.id)
      .and_return(gcs_service)
    allow(BucketService).to receive(:new)
      .with(bucket).and_return(bucket_service)
    allow(ImageValidator).to receive(:new)
      .and_return(image_validator)
  end

  context 'when the image is not valid' do
    before do
      image_validator.status = :unprocessable_entity
      image_validator.error = 'Image failed'
      allow(image_validator).to receive(:determine_validity)
        .and_return(image_validator)
    end

    it 'returns an error response' do
      post "/users/#{user.id}/images",
           params:  params,
           headers: headers

      response_body = JSON.parse(response.body)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response_body['error']).to eq('Image failed')
    end
  end

  context 'when GcsManagementService throws' do
    before do
      allow(gcs_service).to receive(:upload_file)
        .and_raise(GcsManagementService::BucketExistsError)
      image_validator.error = nil
      allow(image_validator).to receive(:determine_validity)
        .and_return(image_validator)
    end

    it 'returns an error response' do
      post "/users/#{user.id}/images",
           params:  params,
           headers: headers

      response_body = JSON.parse(response.body)
      expect(response).to have_http_status(:conflict)
      expect(response_body['error']).to eq('Storage location already exists.')
    end
  end

  context 'when an image saves successfully' do
    before do
      expect(ImageValidator).to receive(:new)
        .and_return(image_validator)
      expect(image_validator).to receive(:determine_validity)
        .and_return(image_validator)
      expect(gcs_service).to receive(:upload_file)
        .and_return(filename)
      expect(bucket_service).to receive(:save_image!)
        .and_return(image)
      expect(image).to receive(:valid?).and_return(true)
    end

    it 'returns a successful response' do
      post "/users/#{user.id}/images",
           params:  params,
           headers: headers

      response_body = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      expect(response_body['message']).to eq('File successfully saved')
    end
  end
end
