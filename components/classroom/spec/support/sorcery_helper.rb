require "sorcery"

module SorceryHelper
  def initialize_sorcery_config!
    ::Sorcery::Controller::Config.init!
    ::Sorcery::Controller::Config.reset!
    ::Sorcery::Controller::Config.user_config do |config|
      config.username_attribute_names = [:username, :email]
    end
  end
end
