require "active_support"

module Formatter
  class Filename
    include ActiveSupport::Inflector

    def initialize(filename)
      @original_filename = @filename = filename
    end

    attr_accessor :filename, :original_filename

    def sanitize
      self.filename = filename
        .downcase
        .gsub(/[^\w\s_\:-]+/, " ") # strip out characters besides letters and digits
        .gsub(/[_\ ]+/, " ") # replace multiple spaces or underscores with single spaces
        .gsub(/\A[ -]+/, "") # remove leading characters \A signifies leading
        .gsub(/[ -]+\z/, "") # remove trailing characters, \z signifies trailing
      self
    end

    # just remove erroneous characters, strip out whitespace, and replace
    # any other consecutive non-alphanum characters with a single underscore
    #
    def url_safe
      self.filename = filename
        .gsub(/[^\w_-]+/, "_") # replace non alphanum characters with underscores
        .gsub(/[ _]+/, "_") # condense redundant underscores
        .gsub(/^_+|_+$/, "") # remove leading or trailing underscores
      self
    end

    # just remove erroneous characters, strip out whitespace, and replace
    # any other consecutive non-alphanum characters with a single underscore
    #
    def directory_name
      self.filename = filename
        .gsub(/[^\w\s_-]+/, "") # remove non alphanum characters
        .gsub(/[_]+/, "_") # condense redundant underscores
        .gsub(/ +/, " ") # condense redundant spaces
        .gsub(/^_+|_+$/, "") # remove leading or trailing underscores
      self
    end

    def reset!
      self.filename = original_filename
    end

    # available ActiveSupport::Inflector behaviors
    INFLECTOR_METHODS = [
      :camelize, :classify, :constantize, :dasherize, :deconstantize,
      :humanize, :ordinalize, :parameterize, :pluralize, :singularize,
      :tableize, :titleize, :underscore
    ]

    class << self
      INFLECTOR_METHODS.each do |inflector_method|
        define_method inflector_method do |filename|
          self.new(filename).sanitize.send(inflector_method).filename
        end
      end
    end

    # add chaining behaviors for inflector methods
    INFLECTOR_METHODS.each do |inflector_method|
      # if there's no exclamation return the object
      define_method inflector_method do
        self.filename = filename.send inflector_method
        self
      end

      # if there's an exclamation return the filename
      define_method "#{inflector_method}!" do
        self.filename = filename.send inflector_method
        filename
      end
    end
  end
end
