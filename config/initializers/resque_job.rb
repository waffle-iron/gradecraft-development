require 'resque_job'

ResqueJob.configure do |config|
  config.backoff_strategy = EventLogger.configuration.backoff_strategy
end
