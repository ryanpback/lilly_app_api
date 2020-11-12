class AuthorizationService
  SECRET_KEY = Rails.application.secrets.secret_key_base.freeze

  attr_reader :headers, :decoded_token

  def initialize(headers = {})
    @headers = headers
  end

  class << self
    def call(headers)
      AuthorizationService.new(headers).authorize_user
    end

    def encode_token(payload, exp = 2.days.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, SECRET_KEY)
    end
  end

  def authorize_user
    return nil unless decoded_token

    user_id = decoded_token[0]['user_id']
    User.find_by(id: user_id)
  end

  def auth_header
    # { Authorization: 'Bearer <token>' }
    headers['Authorization']
  end

  def decoded_token
    @decoded_token ||=
      begin
        return nil unless auth_header

        token = auth_header.split(' ')[1]
        begin
          JWT.decode(token, SECRET_KEY, true, algorithm: 'HS256')
        rescue JWT::DecodeError
          nil
        end
      end
  end
end
