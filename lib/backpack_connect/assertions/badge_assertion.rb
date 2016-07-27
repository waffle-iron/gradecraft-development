#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  module Assertions
    class BadgeAssertion
      attr_accessor :uid, :recipient, :badge, :verify, :issuedOn, :image,
        :evidence, :expires

      def initialize(badge, user, url, verification)
        @uid = badge.id
        @recipient = IdentityObject.new({
          identity: user.id,
          type: "email",
          hashed: false,
          salt: nil
        })
        # @badge = api_badge_class_assertion_path
        @badge = url
        @verify = VerificationObject.new({
          type: verification[:type],
          url: "/api/badge_class_assertion/1"
        })
        @issuedOn = DateTime.now
        @image = badge.icon
      end
    end
  end
end
