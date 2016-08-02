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
          identity: user.username,
          type: "email",  # currently the only supported value?
          hashed: false,
          salt: nil
        })
        @badge = url
        @verify = VerificationObject.new(verification)
        @issuedOn = DateTime.now
        # @image = badge.icon # optional
      end
    end
  end
end
