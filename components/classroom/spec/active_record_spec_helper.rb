ENV["RAILS_ENV"] ||= "test"
require "spec_helper"
require "active_record"
require "factory_girl"
require "faker"
require "yaml"

require_relative "support/sorcery_helper"

Dir["./app/models/concerns/*.rb"].each { |f| require f }
Dir["./app/models/*.rb"].each { |f| require f }

FactoryGirl.factories.clear
FactoryGirl.find_definitions

connection_info = YAML.load_file("../../config/database.yml")["test"]
ActiveRecord::Base.establish_connection(connection_info)

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
