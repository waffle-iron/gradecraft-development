require "./lib/collection_merger"

module Historical
  extend ActiveSupport::Concern

  class HistoryItem
    attr_accessor :changeset
    attr_reader :version

    def initialize(version)
      @version = version
      @changeset = @version.changeset.dup
    end
  end

  included do
    has_paper_trail
  end

  def has_history?
    !history.empty?
  end

  def history
    @history ||= self.versions.reverse.map do |version|
      history = HistoryItem.new(version)
      history.changeset.merge!("object" => self.class.name,
                               "event" => version.event,
                               "actor_id" => version.whodunnit,
                               "recorded_at" => version.created_at)
      history
    end
  end

  def historical_merge(historical_model)
    return self if historical_model.nil?

    self.history = CollectionMerger.new(self.history, historical_model.history)
      .merge(field: ->(history) { history.changeset["recorded_at"] },
             order: :desc)
    self
  end

  def historical_collection_merge(historical_collection)
    return self if historical_collection.nil? || historical_collection.empty?

    historical_collection.each { |historical_model| historical_merge(historical_model) }
    self
  end

  def squish_history!(timeout_in_milliseconds=36_000) # 10 minutes
    PaperTrailVersionSquisher.new(self).squish!(timeout_in_milliseconds)
  end

  private

  def history=(history)
    @history = history
  end
end
