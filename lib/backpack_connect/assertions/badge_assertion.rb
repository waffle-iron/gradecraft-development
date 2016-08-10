#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  module Assertions
    class BadgeAssertion
      attr_accessor :uid, :recipient, :badge, :verify, :issuedOn, :image,
        :evidence, :expires

      def initialize(badge, user, badge_class_url, verification_options)
        @uid = badge.id
        @recipient = IdentityObject.new({
          identity: user.username,
          type: "email",  # currently the only supported value?
          hashed: false,
          salt: nil
        })
        @badge = badge_class_url
        @verify = VerificationObject.new(verification_options)
        @issuedOn = DateTime.now
      end
    end
  end
end
