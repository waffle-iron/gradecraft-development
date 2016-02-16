require "spec_helper"
require "active_record"
require "active_support/core_ext"
require "acts_as_list"
require "aws-sdk"
# require "aws"
require "canable"
require "carrierwave"
require "carrierwave/orm/activerecord"
require "csv"
require "factory_girl"
require "faker"
require "protected_attributes"
require "sanitize"
require "sorcery"
require "yaml"
require "./lib/display_helpers"
require "./lib/model_addons/advanced_rescue"
require "./lib/model_addons/improved_logging"
require "./lib/s3_manager"
require_relative "support/sorcery_stubbing"
require_relative "support/file_helpers"
require_relative "support/world"

# stub out the process_in_background for carrierwave_backgrounder
module CarrierWave
  module Backgrounder
    module Delay; end
  end
end
class ActiveRecord::Base
  def self.process_in_background(_); end
end

SorceryStubbing.sorcery_reset [:user_activation], user_activation_mailer: SorceryStubbing::TestUserMailer

connection_info = YAML.load_file("config/database.yml")["test"]
ActiveRecord::Base.establish_connection(connection_info)

# supress the warning that is generated from CarrierWave because it uses
# after_commit/after_save callbacks
ActiveRecord::Base.raise_in_transactional_callbacks = true

require "paper_trail"
require "paper_trail/frameworks/rspec"

# stub out Rails.env
unless defined?(Rails)
  module Rails
    def self.env
      ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"])
    end
  end
end

Dir["./app/uploaders/*.rb"].each { |f| require f }
Dir["./app/validators/*.rb"].each { |f| require f }
Dir["./app/models/concerns/*.rb"].each { |f| require f }
Dir["./app/models/*.rb"].each { |f| require f }

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false
end

# Uploader classes for which #store_dir shouldn't be overwritten
AttachmentUploader

CarrierWave::Uploader::Base.descendants.each do |klass|
  next if klass.anonymous?
  klass.class_eval do
    def cache_dir
      File.join(File.dirname(__FILE__), "support/uploads/tmp")
    end

    next if klass == AttachmentUploader
    def store_dir
      File.join(File.dirname(__FILE__), "support/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}")
    end
  end
end

FactoryGirl::SyntaxRunner.send(:include, FileHelpers)

RSpec.configure do |config|
  config.include FileHelpers
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.factories.clear
    FactoryGirl.find_definitions
  end

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
