require "httparty"

module BackpackConnect
  class API
    include HTTParty
    format :json

    attr_reader :authenticator

    def initialize(authenticator)
      @authenticator = authenticator
    end

    def issue(badge, params={})
      if (@authenticator.nil?)
        raise SecurityError, "User has not granted permissions to export badges"
        # todo some sort of custom error for this lib
      else
        assertion = Assertions::BadgeAssertion.new({
          uid: "123abc",
          # badge: api_openbadges_badge_class_url(badge.id)
          badge: "https://badge.com"
        })
        puts "assertion = #{assertion}"
        url = "#{@authenticator.api_root}/issue"
        self.class.get(url, query: params)
      end
    end
  end
end
