GradeCraft::Application.configure do
  config.action_controller.default_url_options = { :host => "www.gradecraft.com" }
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
  config.action_dispatch.default_headers = { "X-Frame-Options" => "ALLOWALL" }
  config.asset_host = "https://www.gradecraft.com"
  config.action_mailer.default_url_options = { :host => "www.gradecraft.com" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: "smtp.sparkpostmail.com",
    authentication: :plain,
    enable_starttls_auto: true,
    password: ENV.fetch("SPARKPOST_SMTP_PASSWORD"),
    port: 587,
    user_name: ENV.fetch("SPARKPOST_SMTP_USERNAME")
  }
  config.active_support.deprecation = :notify
  config.assets.compile = false
  config.assets.compress = true
  config.assets.css_compressor = :sass
  config.assets.digest = true
  config.assets.js_compressor = Uglifier.new(mangle: false) if defined? Uglifier
  config.cache_classes = true
  config.cache_store = :dalli_store, ENV["MEMCACHED_URL"], { :namespace => "gradecraft_production", :expires_in => 1.day, :compress => true }
  config.consider_all_requests_local = false
  config.eager_load = true
  config.i18n.fallbacks = true
  config.log_level = :debug
  config.serve_static_files = false
  config.session_store :active_record_store, :expire_after => 60.minutes
end

CarrierWave.configure do |config|
  config.storage = :fog
end
