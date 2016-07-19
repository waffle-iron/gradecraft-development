require "httparty"

module BackpackConnect
  class API
    include HTTParty
    format :json

    attr_reader :authenticator

    def initialize(authenticator)
      @authenticator = authenticator
    end

    def issue(params={})
      if (@authenticator.nil?)
        raise SecurityError, "User has not granted permissions to export badges"
        # todo some sort of custom error for this lib
      else
        url = "#{@authenticator.api_root}/issue"
        self.class.get(url, query: params)
      end
    end
  end
end
