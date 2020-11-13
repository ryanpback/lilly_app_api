require 'spec_helper'
include DataHelpers

describe AuthorizationService do
  let(:user) { User.create(USER_DATA) }
  let(:payload) { { user_id: user.id } }
  let(:expiration) { 2.days.from_now }
  let(:encoded_token) do
    described_class.encode_token(payload, expiration)
  end
  let(:decoded_token) do
    described_class.decode_token(encoded_token)
  end
  let(:headers) { { 'Authorization' => "Bearer #{encoded_token}" } }
  subject { described_class.new(headers) }

  before do
    allow(described_class).to receive(:new)
      .with(headers).and_return(subject)
  end

  describe '.call' do
    it 'creates a new instance and calls #authorize_user' do
      expect(described_class).to receive(:new).with(headers)
      expect(subject).to receive(:authorize_user)
      described_class.call(headers)
    end
  end

  describe '.encode_token' do
    it 'encodes a token with a payload and an expiration date' do
      enc_token = described_class.encode_token(payload, expiration)
      expect(enc_token).to eq(encoded_token)
    end
  end

  describe '.decode_token' do
    context 'when the token can be decoded' do
      it 'decodes a token and returns a user_id and expiration date' do
        dec_token = described_class.decode_token(encoded_token)[0]

        expect(dec_token['user_id']).to eq(user.id)
        expect(dec_token['expiration']).to eq(expiration.to_i)
      end
    end

    context 'when the token fails to decode' do
      before do
        allow(JWT).to receive(:decode).with(any_args).and_raise(JWT::DecodeError)
      end

      it 'returns nil' do
        expect { JWT.decode(any_args) }.to raise_exception(JWT::DecodeError)
        expect(described_class.decode_token(encoded_token)).to be_nil
      end
    end
  end

  describe '#auth_header' do
    context 'when Authorization header exists' do
      it 'returns "Bearer <token>"' do
        expect(subject.auth_header).to eq("Bearer #{encoded_token}")
      end
    end

    context 'when Authorization header doesn\'t exist' do
      let(:headers) { {} }

      it 'returns nil' do
        expect(subject.auth_header).to be_nil
      end
    end
  end

  describe '#authorize_user' do
    context 'when the token can be decoded' do
      it 'returns the user by user_id in the key' do
        expect(subject.authorize_user).to eq(user)
      end

      context 'when the user is not found' do
        let(:payload) { { user_id: 232323 } }
        it 'returns nil' do
          expect(subject.authorize_user).to be_nil
        end
      end
    end

    context 'when the token can\'t be decoded' do
      before do
        allow(subject).to receive(:decoded_token).and_return(nil)
      end

      it 'returns nil' do
        expect(subject.authorize_user).to be_nil
      end
    end
  end

  describe '#decoded_token' do
    context 'when there is an auth header' do
      it 'returns a decoded token' do
        expect(subject.decoded_token).to eq(decoded_token)
      end
    end

    context 'when there is no auth header' do
      before do
        allow(subject).to receive(:auth_header).and_return(nil)
      end

      it 'returns nil' do
        expect(subject.decoded_token).to be_nil
      end
    end
  end
end
