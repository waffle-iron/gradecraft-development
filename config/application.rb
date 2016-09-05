require File.expand_path("../boot", __FILE__)


require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "csv"
require "sprockets/railtie"
require "sanitize"

Bundler.require(:default, Rails.env)

module GradeCraft
  class Application < Rails::Application
    config.time_zone = "America/Detroit"
    config.autoload_paths += %W(#{config.root}/lib)

    config.assets.precompile += %w(.svg .eot .otf .woff .ttf)
    config.filter_parameters += [:password]

    config.i18n.enforce_available_locales = true
    config.angular_templates.ignore_prefix  = %w(angular/templates/)
    config.responders.flash_keys = [ :success, :failure ]
    config.generators do |g|
      g.integration_tool :mini_test
      g.orm :active_record
      g.stylesheets :false
      g.template_engine :haml
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: true,
        request_specs: false
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end

    #http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#error-handling-in-transaction-callbacks
    config.active_record.raise_in_transactional_callbacks = true
  end
end
