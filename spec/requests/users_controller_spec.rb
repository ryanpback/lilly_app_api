require 'spec_helper'
include DataHelpers

describe UsersController, type: :request do
  let(:user_params) { USER_DATA }
  let(:user) { User.create(user_params) }
  let(:token) { AuthorizationService.encode_token({ user_id: user.id }) }
  let(:headers) { { 'Authorization': "Bearer #{token}" } }

  describe '#register' do
    context 'when a user successfully registers' do
      before do
        allow(RegistrationService).to receive(:complete_registration).and_return(user, nil)
        allow(AuthorizationService).to receive(:encode_token).and_return(token)
      end

      it 'returns a successful response' do
        post '/register', params: user_params

        response_body = JSON.parse(response.body)
        expect(response).to have_http_status(:created)
        expect(response_body['token']).to eq(token)
        expect(response_body['message']).to match(/User #{user.username} created successfully/)
      end
    end

    context 'when registering a user has errors' do
      before do
        user.errors.add(:base)
        allow(RegistrationService).to receive(:complete_registration).and_return([user, user.errors])
      end

      it 'returns an error response' do
        post '/register', params: user_params

        response_body = JSON.parse(response.body)
        expect(response).to have_http_status(:conflict)
        expect(response_body['error']).to be_kind_of(Hash)
      end
    end

    context 'when registering a user throws an exception' do
      let(:error_message) { 'boo' }

      before do
        allow(RegistrationService).to receive(:complete_registration)
          .and_raise(RegistrationService::RegistrationError, error_message)
      end

      it 'rescues the exception and returns an error response' do
        post '/register', params: user_params

        response_body = JSON.parse(response.body)
        expect(response).to have_http_status(:internal_server_error)
        expect(response_body['error']).to eq(error_message)
      end
    end
  end

  describe '#login' do
    context 'when user logs in successfully' do
      before do
        allow(User).to receive(:find_by).and_return(user)
      end

      it 'returns a successful response' do
        post '/login',
             params: {
               username: user.username,
               password: user_params[:password],
             }

        response_body = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(response_body['token']).to eq(token)
        expect(response_body['user']).to eq(
          {
            'id'         => user.id,
            'first_name' => user.first_name,
            'last_name'  => user.last_name,
            'username'   => user.username,
            'email'      => user.email,
          },
        )
      end
    end

    context 'when user login is unsuccessful' do
      before do
        allow(User).to receive(:find_by).and_return(nil)
      end

      it 'returns an error response' do
        post '/login',
             params: {
               username: user.username,
               password: user.password,
             }

        response_body = JSON.parse(response.body)
        expect(response).to have_http_status(:unauthorized)
        expect(response_body['error']).to match(/Invalid username or password/)
      end
    end
  end

  describe '#destroy' do
    context 'when a user is successfully unregistered' do
      before do
        allow(RegistrationService).to receive(:unregister_user)
          .and_return(true)
      end

      it 'returns a successful response' do
        delete "/users/#{user.id}", headers: headers
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when a user is unsuccessfully unregistered' do
      before do
        allow(RegistrationService).to receive(:unregister_user)
          .and_return(false)
      end

      it 'returns an error message' do
        delete "/users/#{user.id}", headers: headers
        expect(response).to have_http_status(:reset_content)
      end
    end
  end
end
