# this module is the initial declaration and entry point for the ResqueJob
# library. It should be used for all system Resque jobs that don't directly
# interact with the Analytics library or log events. In those instances the
# similar EventLogger library should be used since it's tailored to
# specifically handling jobs that are responsible for logging events in mongo

module ResqueJob
  extend IsConfigurable
end

require_dependency 'is_configurable'
require_dependency 'resque_job/base'
require_dependency 'resque_job/configuration'
require_dependency 'resque_job/outcome'
require_dependency 'resque_job/performer'
require_dependency 'resque_job/step'
require_dependency 'resque_job/errors/forced_retry_error'
