require_relative "badge_proctor/base"
require_relative "badge_proctor/viewable"

# determines what sort of CRUD operations can be performed
# on a `badge` resource
class BadgeProctor
  include Viewable

  attr_reader :badge

  def initialize(badge)
    @badge = badge
  end
end
