require "httparty"
require "base64"

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
        raise Exception, "User has not granted permissions to export badges"
      end
      querystring = { badge: assertion }.to_json
      HTTParty.post("#{@authenticator.api_root}/issue", {
        :body => querystring,
        :headers => { "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ Base64.encode64(@authenticator.access_token) }"
        }
      })
    end
  end
end
