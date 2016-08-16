module BackpackConnect
  class Authenticator
    attr_accessor :error, :expires, :api_root, :access_token, :refresh_token

    def initialize(options={})
      options.each do |key, value|
        instance_variable_set("@#{key}", value) unless value.nil?
      end
    end
  end
end
