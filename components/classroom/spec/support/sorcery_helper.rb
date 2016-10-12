require "sorcery"

module SorceryHelper
  def initialize_sorcery_config!(klass)
    ::Sorcery::Controller::Config.init!
    ::Sorcery::Controller::Config.reset!

    klass.sorcery_config.downcase_username_before_authenticating = true
    klass.sorcery_config.username_attribute_names = [:username, :email]
  end
end
