class UsersController < ApplicationController
  skip_before_action :authorize,
                     only: %i(register login)

  def register
    @user         = User.new(user_params)
    @user, errors = RegistrationService.complete_registration(user: @user)

    return render json: { error: errors.to_hash(true) }, status: :conflict unless errors.blank?

    token = AuthorizationService.encode_token({ user_id: @user.id })
    response = {
      message: "User #{@user.username} created successfully",
      token:   token,
    }

    render json: response, status: :created
  rescue RegistrationService::RegistrationError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def login
    @user = User.find_by(username: params[:username])

    if @user&.authenticate(params[:password])
      token = AuthorizationService.encode_token({ user_id: @user.id })

      response = {
        user:  {
          id:         @user.id,
          first_name: @user.first_name,
          last_name:  @user.last_name,
          username:   @user.username,
          emai:       @user.email,
        },
        token: token,
      }

      render json: response, status: :ok
    else
      response = { error: 'Invalid username or password' }

      render json: response, status: :unauthorized
    end
  end

  def destroy
    user_deleted =
      RegistrationService.unregister_user(user: @current_user)

    if user_deleted
      render json: { message: 'Successfully unregistered from LillyApp' }, status: :no_content
    else
      render json: { error: 'Failed to unregister. Please try again.' }, status: :reset_content
    end
  end

  private

  def user_params
    params.permit(:first_name, :last_name, :email, :username, :password)
  end
end
