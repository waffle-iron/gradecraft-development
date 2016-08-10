#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  class Assertions::BadgeClass
    attr_accessor :name, :description, :image, :criteria, :issuer, :alignment,
      :tags

    def initialize(badge, issuer, host)
      @name = badge.name
      @description = badge.description
      @issuer = issuer  # URL of the organization issuing the badge - endpoint should be an IssuerOrganization
      @image = "#{host}#{badge.icon}"
      @criteria = "localhost:5000/badges/1" #todo this
    end
  end
end
