require "httparty"
require "base64"
require "byebug"

module BackpackConnect
  class API
    include HTTParty
    format :json

    attr_reader :authenticator

    def initialize(authenticator)
      @authenticator = authenticator
    end

    def issue(assertion)
      if (@authenticator.nil?)
        raise SecurityError, "User has not granted permissions to export badges"
      end
      response = HTTParty.post("#{@authenticator.api_root}/issue", {
        body: { badge: assertion }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      })
    end
  end
end
