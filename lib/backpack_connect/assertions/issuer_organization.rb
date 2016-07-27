#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  class Assertions::IssuerOrganization
    attr_accessor :name, :url, :description, :image, :email, :revocationList
  end
end
