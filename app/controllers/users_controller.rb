class UsersController < ApplicationController
  skip_before_action :authorize, except: %i[auto_login]

  def register
    @user = User.new(user_params)
    @user, errors = RegistrationCompletion.complete_registration(user: @user)

    unless errors.blank?
      return render json: { error: errors.to_hash(true) }, status: :conflict
    end

    token = AuthorizationService.encode_token({ user_id: @user.id })
    response = {
      message: "User #{@user.username} created successfully",
      token: token
    }

    render json: response, status: :created
  rescue RegistrationCompletion::RegistrationError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def login
    @user = User.find_by(username: params[:username])

    if @user&.authenticate(params[:password])
      token = AuthorizationService.encode_token({ user_id: @user.id })

      response = {
        user: {
          id: @user.id,
          first_name: @user.first_name,
          last_name: @user.last_name,
          username: @user.username,
          emai: @user.email
        },
        token: token
      }

      render json: response, status: :ok
    else
      response = { error: 'Invalid username or password' }

      render json: response, status: :unauthorized
    end
  end

  def auto_login
    render json: @current_user, status: :ok
  end

  private

  def user_params
    params.permit(:first_name, :last_name, :email, :username, :password)
  end
end
