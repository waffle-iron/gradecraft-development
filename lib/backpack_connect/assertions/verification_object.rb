#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  class Assertions::VerificationObject
    attr_accessor :type, :url

    def initialize(options={})
      @type = options[:type]
      @url = options[:url]
    end
  end
end
