class BackpackConnectAuthenticator
  def initialize(error:, expires:, api_root:, access_token:, refresh_token:)
    method(__method__).parameters.each do |param_type, keyword|
      send "#{keyword}=", binding.local_variable_get(keyword)
    end
  end

  attr_accessor :error, :expires, :api_root, :access_token, :refresh_token

  def access_token_expired?
    return false unless access_token
    false #todo expiration check
  end
end
