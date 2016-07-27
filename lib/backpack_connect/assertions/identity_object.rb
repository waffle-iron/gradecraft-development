#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  class Assertions::IdentityObject
    attr_accessor :identity, :type, :hashed, :salt

    def initialize(options={})
      @identity = options[:identity]  #probably an email?
      @type = options[:type] #will need to double-check what this means
      @hashed = options[:hashed]
      @salt = options[:salt]
    end
  end
end
