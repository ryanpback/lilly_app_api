class AuthorizationService
  SECRET_KEY = Rails.application.secret_key_base.freeze
  ENC_ALGORITHM = Rails.application.credentials.jwt[:enc_algorithm].freeze

  attr_reader :headers, :decoded_token

  def initialize(headers = {})
    @headers = headers
  end

  class << self
    def call(headers)
      AuthorizationService.new(headers).authorize_user
    end

    def encode_token(payload, exp = 2.days.from_now)
      payload[:expiration] = exp.to_i
      JWT.encode(payload, SECRET_KEY, ENC_ALGORITHM)
    end

    def decode_token(token)
      JWT.decode(
        token,
        SECRET_KEY,
        true,
        algorithm: ENC_ALGORITHM,
      )
    rescue JWT::DecodeError
      nil
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
    return nil unless auth_header

    @decoded_token ||=
      begin
        token = auth_header.split(' ')[1]
        self.class.decode_token(token)
      end
  end
end
