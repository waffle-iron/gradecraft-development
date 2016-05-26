class FileSizeValidator < ActiveModel::EachValidator
  CHECKS = { is: :==, minimum: :>=, maximum: :<= }.freeze
  MESSAGES  = {
    is: :wrong_size, minimum: :size_too_small, maximum: :size_too_big
  }.freeze
  RESERVED_OPTIONS  = [:minimum, :maximum, :within, :is, :too_short, :too_long]

  def initialize(options)
    if range = (options.delete(:in) || options.delete(:within))
      raise ArgumentError, ":in and :within must be a Range" unless range.is_a?(Range)
      options[:minimum] = range.begin
      options[:maximum] = range.end
      options[:maximum] -= 1 if range.exclude_end?
    end
    super
  end

  def validate_each(record, attribute, value)
    raise(ArgumentError, "A CarrierWave::Uploader::Base object was expected") \
      unless value.kind_of? CarrierWave::Uploader::Base

    CHECKS.each do |key, validity_check|
      next unless check_value = options[key]

      value ||= [] if key == :maximum

      begin
        value_size = value.size
      rescue
        next
      end

      next if value_size.send(validity_check, check_value)

      errors_options = options.except(*RESERVED_OPTIONS)
      errors_options[:file_size] = help.number_to_human_size check_value

      default_message = options[MESSAGES[key]]
      errors_options[:message] ||= default_message if default_message

      record.errors.add(attribute, MESSAGES[key], errors_options)
    end
  end

  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper if defined? ActionView
  end
end
