require "resque-retry"
require "resque/errors"

module ResqueJob
  class Base
    # add resque-retry for all jobs
    extend Resque::Plugins::Retry
    extend Resque::Plugins::ExponentialBackoff
    extend LogglyResque # pulls in logger class method for logging to Loggly, defines #logger
    extend InheritableIvars # pass designated ivars from #inheritable_ivars down to descendent subclasses

    # defaults
    @queue = :main # put all jobs in the 'main' queue
    @performer_class = ResqueJob::Performer

    class << self
      attr_reader :performer_class, :queue
    end

    # perform block that is ultimately called by Resque
    def self.perform(attrs={})
      begin
        logger.info self.start_message(attrs) # start us off with some info about what's happening
        performer = @performer_class.new(attrs, logger) # self.class is the job class
        performer.do_the_work # this is where the magic happens
        log_outcomes(performer.outcomes) # tells us what actually went down
      rescue Exception => e
        logger.info "Error in #{@performer_class.to_s}: #{e.message}"
        logger.info e.backtrace
        raise ResqueJob::Errors::ForcedRetryError # force the retry in ResqueRetry if the #perform attempt fizzes out
      end
    end
    attr_reader :attrs

    # override the backoff strategy from Resque::ExponentialBackoff
    def self.backoff_strategy
      @backoff_strategy ||= ResqueJob.configuration.backoff_strategy
    end

    def initialize(attrs={})
      @attrs = attrs
    end

    def enqueue_in(time_until_start)
      Resque.enqueue_in(time_until_start, self.object_class, @attrs)
    end

    def enqueue_at(scheduled_time)
      Resque.enqueue_at(scheduled_time, self.object_class, @attrs)
    end

    def enqueue
      Resque.enqueue(self.object_class, @attrs)
    end

    def enqueue_with_fallback
      # schedule the event in the background if Resque is available
      enqueue
    rescue
      # otherwise just perform
      self.class.perform @attrs
    end

    def self.start_message(attrs)
      @start_message || "Starting #{self.job_type} in queue '#{@queue}' with attributes #{attrs}."
    end

    def self.log_outcomes(outcomes)
      outcomes.each do |outcome|
        logger.info "SUCCESS: #{outcome.message}" if outcome.success?
        logger.info "FAILURE: #{outcome.message}" if outcome.failure?
        logger.info "RESULT: #{outcome.result_excerpt}"
      end
    end

    def self.object_class
      self.new.class
    end

    def object_class
      self.class
    end

    def self.job_type
      self.new.class.name
    end

    def self.inheritable_ivars
      [
        :queue,
        :performer_class
      ]
    end
  end
end
