require 'spec_helper'

describe User do
  let(:first_name) { 'Test' }
  let(:last_name) { 'User' }
  let(:username) { 'testuser' }
  let(:email) { 'testuser@test.com' }
  let(:password) { 'password123' }
  let(:params) {
    {
      first_name: first_name,
      last_name: last_name,
      username: username,
      email: email,
      password: password
    }
  }
  let(:user) { described_class.create(params) }
  let(:bucket) { user.create_bucket }
  let(:filename1) { 'testfile1' }
  let(:filename2) { 'testfile2' }
  let(:image1) { bucket.images.create(filename: filename1) }
  let(:image2) { bucket.images.create(filename: filename2) }

  describe '#user_image_by_id' do
    it 'should return an image' do
      expect(user.user_image_by_id(image1.id)).to be_kind_of(Image)
    end

    it 'should return the bucket id that the image queried by id belongs to' do
      expect(user.user_image_by_id(image1.id).bucket_id).to eq(bucket.id)
    end

    it 'should return the image with the ID that was passed in' do
      image = user.user_image_by_id(image1.id)
      expect(image.id).to eq(image1.id)
      expect(image.id).to_not eq(image2.id)
    end

    it 'should return the filename of the image queried by id' do
      image = user.user_image_by_id(image1.id)
      expect(image.filename).to eq(filename1)
      expect(image.filename).to_not eq(filename2)
    end
  end

  describe ".create_user" do
    context 'when all data is present and valid' do
      it 'produces no errors when saving' do
        expect(described_class.create(params).errors).to be_blank
      end
    end

    context 'when user information fails presence validation' do
      context 'when first name is blank or missing' do
        let(:first_name) { '' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/first_name.+can\'t be blank/)
        end
      end

      context 'when last name is blank or missing' do
        let(:last_name) { '' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/last_name.+can\'t be blank/)
        end
      end

      context 'when username is blank or missing' do
        let(:username) { '' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/username.+can\'t be blank/)
        end
      end

      context 'when email is blank or missing' do
        let(:email) { '' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/email.+can\'t be blank/)
        end
      end

      context 'when password is blank or missing' do
        let(:password) { '' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/password.+can\'t be blank/)
        end
      end
    end

    context 'when user information fails format validation' do
      context 'when email is improperly formatted' do
        let(:email) { 'testuser.com' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/email.+is invalid/)
        end
      end

      context 'when password is too short' do
        let(:password) { 'tooshort' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/password.+is too short/)
        end
      end

      context 'when password is too long' do
        let(:password) { 'thisisfartoolongandshouldfailvalidation' }

        it 'fails to save with error message' do
          user = described_class.create(params)
          expect(user.errors.messages.to_s).to match(/password.+is too long/)
        end
      end
    end

    context 'when user information fails uniqueness validation' do
      context 'when username is not unique' do
        # username is the same in the params. Changing email
        # to narrow down to one validation error
        let(:non_duplicate_email) { 'notusersemail@test.com' }

        it 'fails to save with error message' do
          described_class.create(params)
          user = described_class.create(first_name: first_name, last_name: last_name, username: username, email: non_duplicate_email, password: password)

          expect(user.errors.messages.to_s).to match(/username.+already been taken/)
        end
      end

      context 'when email is not unique' do
        # email is the same in the params. Changing username
        # to narrow down to one validation error
        let(:non_duplicate_username) { 'uniquename' }

        it 'fails to save with error message' do
          described_class.create(params)
          user = described_class.create(first_name: first_name, last_name: last_name, username: non_duplicate_username, email: email, password: password)

          expect(user.errors.messages.to_s).to match(/email.+already been taken/)
        end
      end
    end
  end
end
