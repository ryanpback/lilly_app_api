class RegistrationService
  class RegistrationError < StandardError; end

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def self.complete_registration(user:)
    new(user).register
  end

  def self.unregister_user(user:)
    new(user).unregister
  end

  # Save user and create a bucket to get a unique bucket UUID.
  # If, for some reason, the bucket fails on creation,
  # delete the user and raise and exception
  def register
    if user.save
      begin
        user.create_bucket
      rescue StandardError # Not sure what error could/would be thrown - catch all
        user.destroy

        raise RegistrationError, 'Something went wrong creating the user. Try again.'
      end
    end

    return user, user.errors
  end

  def unregister
    bucket = user.bucket
    deleted_from_gcs =
      GcsManagementService.new(bucket.id).delete_bucket

    return false unless deleted_from_gcs

    return false unless bucket.destroy

    user.destroy

    user.destroyed?
  end
end
