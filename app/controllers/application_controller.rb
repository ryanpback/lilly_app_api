class ApplicationController < ActionController::API
  before_action :authorize

  def authorize
    @current_user = AuthorizationService.call(request.headers)

    # User doesn't exist from user_id in token
    return render json: { message: 'Please log in' }, status: :unauthorized unless @current_user

    # User in params doesn't match user in token
    render json: {
      error: 'Unauthorized'
    }, status: :unauthorized unless params[:user_id] &&
      @current_user.id == params[:user_id]
  end
end
