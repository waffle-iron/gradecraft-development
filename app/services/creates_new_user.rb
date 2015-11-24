require "light-service"
require_relative "creates_new_user/build_user"

module Services
  class CreatesNewUser
    extend LightService::Organizer

    def self.create(attributes)
      with(attributes: attributes).reduce(
        Actions::BuildsUser,
        Actions::GeneratesPassword,
        Actions::SavesUser
      )
    end
  end
end
