class ApplicationController < ActionController::API
  before_action :authorize

  def authorize
    @current_user = AuthorizationService.call(request.headers)

    render json: { message: 'Please log in' }, status: :unauthorized unless @current_user
  end
end
