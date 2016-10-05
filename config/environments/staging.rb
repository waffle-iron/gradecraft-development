GradeCraft::Application.configure do
  config.action_controller.default_url_options = { :host => "staging.gradecraft.com" }
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
  config.asset_host = ENV["GC_ASSET_HOST"] || "https://staging.gradecraft.com"
  config.action_mailer.default_url_options = { :host => "staging.gradecraft.com" }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => ENV.fetch("MAILCATCHER_HOST"], "gcmailcatcher"),
    :port => ENV.fetch("MAILCATCHER_PORT", 25).to_i,
  }
  config.action_mailer.perform_deliveries = true

  config.active_support.deprecation = :notify
  config.assets.compile = ["1", "yes", "true", "on"].include?(ENV["GC_ASSETS_COMPILE"] || "0" )
  config.assets.compress = true
  config.assets.css_compressor = :sass
  config.assets.digest = true
  config.assets.js_compressor = :uglifier
  config.cache_classes = true
  config.cache_store = :dalli_store, ENV["MEMCACHED_URL"], { :namespace => "gradecraft_staging", :expires_in => 1.day, :compress => true }
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.log_level = :debug

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  config.serve_static_files = ["1", "yes", "true", "on"].include?(ENV["GC_SERVE_STATIC_FILES"] || "0" )
  config.session_store :active_record_store, :expire_after => 60.minutes
end

CarrierWave.configure do |config|
  config.storage = :fog
end
