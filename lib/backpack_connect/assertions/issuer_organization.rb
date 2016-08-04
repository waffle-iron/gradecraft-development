#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  class Assertions::IssuerOrganization
    attr_accessor :name, :url, :description, :image, :email, :revocationList

    def initialize(options)
      options.each do |key, value|
        instance_variable_set("@#{key}", value) unless value.nil?
      end
    end
  end
end
