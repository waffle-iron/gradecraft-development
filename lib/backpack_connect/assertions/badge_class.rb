#https://github.com/mozilla/openbadges-specification/blob/master/Assertion/latest.md#identityhash
# for additional information regarding assertions

module BackpackConnect
  class Assertions::BadgeClass
    attr_accessor :name, :description, :image, :criteria, :issuer, :alignment,
      :tags

    def initialize(badge)
      @uid = badge.name
      @description = badge.description
      @image = badge.icon
    end
  end
end
