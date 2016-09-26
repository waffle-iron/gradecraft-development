require "mongoid/config/environment"

Mongoid.configure do |config|
  mongodb_uri_raw = ENV.fetch 'MONGODB_URI', false

  if mongodb_uri_raw
    mongodb_uri, mongodb_options_raw = mongodb_uri_raw.split('?')

    mongodb_options = {}
    if mongodb_options_raw
      CGI::parse(mongodb_options_raw).each do |param, values|
        mongodb_options[param.to_sym] = values.last.to_i
      end
    end

    settings = {
      sessions: {
          default: {
            uri: mongodb_uri,
            options: mongodb_options
          }
        }
      }

    config.load_configuration settings
  end
end
