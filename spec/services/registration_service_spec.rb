require 'spec_helper'

describe RegistrationService do
  let(:first_name) { 'Test' }
  let(:last_name) { 'User' }
  let(:username) { 'testuser' }
  let(:email) { 'testuser@test.com' }
  let(:password) { 'password123' }
  let(:valid_params) do
    {
      first_name: first_name,
      last_name:  last_name,
      username:   username,
      email:      email,
      password:   password,
    }
  end
  let(:invalid_params) { valid_params.except(:first_name) }
  let(:user) { User.new(valid_params) }
  let(:user_with_error) { User.create(invalid_params) }
  let(:unregistered_user_subject) { described_class.new(user) }
  let(:registered_user) { User.create(valid_params) }
  let(:registered_user_subject) { described_class.new(registered_user) }
  let(:bucket) { registered_user.create_bucket }
  let(:image) { bucket.images.create(filename: 'testfile') }
  let(:gcs_service) { GcsManagementService.new(bucket.id) }
  let(:bucket_deletion_status) { true }
  let(:user_deletion_status) { true }

  describe '.complete_registration' do
    before do
      allow(described_class).to receive(:new).and_return(unregistered_user_subject)
    end

    context 'when called, it creates a RegistrationService instance' do
      it 'calls #register' do
        expect(described_class).to receive(:new).with(registered_user)
        expect(unregistered_user_subject).to receive(:register)
        described_class.complete_registration(user: registered_user)
      end
    end
  end

  describe '.unregister_user' do
    before do
      allow(described_class).to receive(:new).and_return(unregistered_user_subject)
    end

    context 'when called, it creates a RegistrationService instance' do
      it 'calls #unregister' do
        expect(described_class).to receive(:new).with(user)
        expect(unregistered_user_subject).to receive(:unregister)
        described_class.unregister_user(user: user)
      end
    end
  end

  describe '#register' do
    context 'when a user is successfully created' do
      context 'when it creates a bucket successfully' do
        it 'returns the user' do
          registered_user, = unregistered_user_subject.register
          expect(registered_user).to have_attributes(email: email, username: username)
        end

        it 'returns no errors' do
          _, errors = unregistered_user_subject.register
          expect(errors).to be_blank
        end
      end

      context 'when it fails to create a bucket' do
        before do
          allow(user).to receive(:create_bucket).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'deletes the user and raises exception' do
          expect { unregistered_user_subject.register }.to raise_exception(RegistrationService::RegistrationError)
          expect(User.find_by(email: email)).to be_nil
        end
      end
    end

    context 'when a user is not created' do
      let(:user) { User.new(invalid_params) }

      it 'returns the user' do
        registered_user, = unregistered_user_subject.register
        expect(registered_user).to have_attributes(email: email, username: username)
      end

      it 'returns errors' do
        _, errors = unregistered_user_subject.register
        expect(errors).not_to be_blank
      end
    end
  end

  describe '#unregister' do
    before do
      allow(GcsManagementService).to receive(:new)
        .with(bucket.id).and_return(gcs_service)
      expect(gcs_service).to receive(:delete_bucket)
    end

    context 'when the bucket is not deleted in gcs' do
      before do
        allow(gcs_service).to receive(:delete_bucket).and_return(false)
      end

      it 'returns false and doesn\'t call subsequent methods' do
        expect(bucket).to_not receive(:destroy)
        expect(registered_user).to_not receive(:destroy)
        expect(registered_user_subject.unregister).to eq false
      end
    end

    context 'when a bucket is successfully deleted in gcs' do
      before do
        allow(gcs_service).to receive(:delete_bucket).and_return(true)
        allow(bucket).to receive(:destroy).and_return(bucket_deletion_status)
        allow(registered_user).to receive(:destroyed?).and_return(user_deletion_status)
      end

      context 'when the user and bucket are deleted successfully' do
        it 'returns true' do
          expect(bucket).to receive(:destroy)
          expect(registered_user).to receive(:destroy)
          expect(registered_user_subject.unregister).to eq true
        end
      end

      context 'when the bucket is not deleted' do
        let(:bucket_deletion_status) { false }

        it 'returns false' do
          expect(bucket).to receive(:destroy)
          expect(registered_user).to_not receive(:destroy)
          expect(registered_user).to_not receive(:destroyed?)
          expect(registered_user_subject.unregister).to eq false
        end
      end

      context 'when the user is not deleted' do
        let(:user_deletion_status) { false }

        it 'returns false' do
          expect(bucket).to receive(:destroy)
          expect(registered_user).to receive(:destroy)
          expect(registered_user).to receive(:destroyed?)
          expect(registered_user_subject.unregister).to eq false
        end
      end
    end
  end
end
