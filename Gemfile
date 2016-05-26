source 'https://rubygems.org'

ruby '2.2.2'

gem 'rails'
gem "resque", "1.25.2", git: "https://github.com/resque/resque.git", branch: "1-x-stable"
gem 'actionpack-action_caching'
gem 'activerecord-import'
gem 'actionpack-page_caching'
gem 'active_model_serializers'
gem 'activerecord-session_store'
gem 'acts_as_list'
gem 'addressable'
gem 'angularjs-rails', '~> 1.4.2'
gem 'angular-rails-templates', '~> 0.2.0'

# zip utility for simple creation of zip files, pure ruby implementation
# without the GC overhead of the Rubyzip library
gem 'archive-zip', '~> 0.7.0'

gem 'autonumeric-rails'
gem 'aws-sdk', '~> 2'
gem 's3_direct_upload'
gem 'cancancan'
gem 'carrierwave', '~> 0.10.0'
gem 'carrierwave_backgrounder', '0.4.2'
gem 'coffee-rails'
gem "compass-rails"
gem "d3-rails"
gem 'dalli'

# adds expect{something}.to 'make_database_queries' matchers to rspec
# useful for testing eager/lazy loading
gem 'db-query-matchers'

gem 'dotenv-rails'

gem 'fast_blank'
gem 'fog'
gem 'font-awesome-rails'
gem 'haml'
gem 'ims-lti', git: 'https://github.com/venturit/ims-lti.git', branch: 'master'
gem 'jbuilder'
gem 'jquery-rails'

gem 'light-service'

# interface for connecting to remote logging system Loggly
gem 'logglier', '~> 0.3.0'
# connect to papertrail
# gem 'remote_syslog_logger'
# connect to Loggly/whatever more easily over UDP/TCP
# gem 'syslogger', '~> 1.6.0'
# gem 'lograge','~> 0.3.1'

gem 'multi_json'
gem 'mini_magick'
gem 'moped', '2.0.4', git: 'https://github.com/wandenberg/moped.git', branch: 'operation_timeout'
gem 'mongoid', '~> 4.0.2'
gem 'ng-rails-csrf'
gem 'nokogiri'
gem 'oauth', git: 'https://github.com/venturit/oauth-ruby.git', branch: 'master'
gem 'oink'
gem 'oj'
gem 'omniauth'
gem 'omniauth-kerberos'
gem 'omniauth-lti', git: 'https://github.com/venturit/omniauth-lti.git', branch: 'master'

gem 'pacecar'
gem 'paper_trail'
gem 'pg'
gem 'protected_attributes'
gem 'puma'
gem 'rack-mini-profiler', require: false
gem 'rails_autolink'
gem 'rails_email_preview', '~> 0.2.29'
gem 'rdiscount'

# retry dsl for resque
gem 'resque-retry'

# handles deferrence of Resque jobs to a later time
# ex: Resque.enqueue_in(5.hours, @worker_object)
gem 'resque-scheduler', require: "resque/scheduler"

# slightly more mature rate limiter plugin for resque
# gem 'resque-waiting-room'

# limits the number of jobs that are run per unit of time on a given queue
# ex: Resque.rate_limit(:my_queue, :at => 10, :per => 60)
gem 'resque-throttler', require: "resque/throttler"

gem 'responders'
gem 'rollbar'
gem 'sampler'
gem 'sanitize'
gem 'sassc-rails'

# secure crypt hashing library stronger than bcrypt or PBDBF2
gem 'scrypt'

gem 'select2-rails'
gem 'simple_form'
gem 'sorcery'
gem 'timelineJS-rails', git: 'https://github.com/chcholman/timelineJS-rails.git', branch: 'master'
gem 'uglifier'
gem 'underscore-rails'
gem 'whenever'
gem 'newrelic_rpm'
gem 'sinatra', '>= 1.3.0', require: nil
gem 'wysiwyg-rails'
gem 'ruby-saml', '~> 1.0.0'

group :development do
  gem 'haml-rails'
  gem 'valid_attribute'
  gem 'quiet_assets'
  gem 'foreman'
  gem 'rubystats'
  gem "bullet"

  # setup a simple SMTP server to catch all outgoing mail at smtp://localhost:1025
  gem "mailcatcher"
end

group :development, :test do
  gem 'pry'
  gem 'byebug'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'zeus'
  gem 'better_errors'
end

group :test do
  gem 'capybara', '~> 2.5.0'
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner', '~> 1.5.1'
  gem 'faker', '~> 1.4.3'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'capybara-select2'
  gem 'launchy'
  gem 'rspec-rails', '~> 3.4.0'
  # add spec helpers for testing Resque objects and resque scheduler
  gem 'resque_spec', github: 'leshill/resque_spec'
  gem 'rspec-html-matchers'
  gem 'selenium-webdriver'
  gem 'simplecov'
end

group :tasks do
  gem 'rake-hooks'
end

source 'https://rails-assets.org' do
  gem 'rails-assets-angular', '1.3.15'
  gem 'rails-assets-angular-resource', '1.3.15'
  gem 'rails-assets-lodash', '3.7.0'
  gem 'rails-assets-jquery', '2.1.4'
  gem 'rails-assets-angular-dragdrop', '1.0.11'
  gem 'rails-assets-ngDraggable', '0.1.8'
end
