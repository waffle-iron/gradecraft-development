require "mongoid"
Mongoid.load! "#{Rails.root}/config/mongoid.yml" unless ENV.fetch 'MONGODB_URI', false
