class RegistrationCompletion
  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def self.complete_registration(user:)
    self.new(user).register
  end

  def register
    user.save

    return user, user.errors
  end
end
