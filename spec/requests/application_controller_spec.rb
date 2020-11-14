require 'spec_helper'
include DataHelpers

describe ApplicationController, type: :request do
  let(:user) { User.create(USER_DATA) }
  let(:user_id) { user.id }
  let(:token) do
    AuthorizationService.encode_token({ user_id: user_id })
  end
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  context 'when a user is authorized' do
    before do
      allow(RegistrationService).to receive(:unregister_user).and_return(true)
    end

    it 'returns a no_content status code' do
      delete "/users/#{user.id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end

  context 'when a user isn\'t authorized' do
    let(:user_id) { 1234 }
    it 'returns an unauthorized status code' do
      delete "/users/#{user_id}", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
