require 'spec_helper'

describe RegistrationCompletion do
  let(:first_name) { 'Test' }
  let(:last_name) { 'User' }
  let(:username) { 'testuser' }
  let(:email) { 'testuser@test.com' }
  let(:password) { 'password123' }
  let(:valid_params) {
    {
      first_name: first_name,
      last_name: last_name,
      username: username,
      email: email,
      password: password
    }
  }
  let(:invalid_params) { valid_params.except(:first_name) }
  let(:user) { User.new(valid_params) }
  let(:user_with_error) { User.create(invalid_params) }
  subject { described_class.new(user) }

  describe '.complete_registration' do
    before do
      allow(described_class).to receive(:new).and_return(subject)
    end

    context 'when called, it creates a RegistrationCompletion instance' do
      it 'calls #register' do
        expect(described_class).to receive(:new).with(user)
        expect(subject).to receive(:register)
        described_class.complete_registration(user: user)
      end
    end
  end

  describe '#register' do
    context 'when a user is successfully created' do
      context 'when it creates a bucket successfully' do
        it 'returns the user' do
          registered_user, _ = subject.register
          expect(registered_user).to have_attributes(email: email, username: username)
        end

        it 'returns no errors' do
          _, errors = subject.register
          expect(errors).to be_blank
        end
      end

      context 'when it fails to create a bucket' do
        before do
          allow(user).to receive(:create_bucket).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'deletes the user and raises exception' do
          expect{subject.register}.to raise_exception(RegistrationCompletion::RegistrationError)
          expect(User.find_by(email: email)).to be_nil
        end
      end
    end

    context 'when a user is not created' do
      let(:user) { User.new(invalid_params) }

      it 'returns the user' do
        registered_user, errors = subject.register
        expect(registered_user).to have_attributes(email: email, username: username)
      end

      it 'returns errors' do
        _, errors = subject.register
        expect(errors).not_to be_blank
      end
    end
  end
end
