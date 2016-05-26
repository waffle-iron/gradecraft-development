module ResqueJob
  class Outcome
    def initialize(result, options={})
      @result = result
      @options = options
      @max_result_size = options[:max_result_size]
    end

    attr_accessor :message, :result, :options
    attr_reader :max_result_size

    def success?
      result != false && result != nil
    end

    def failure?
      result == false || result.nil?
    end

    def result_excerpt
      return result unless max_result_size
      "#{result}"[0..max_result_size]
    end
  end
end
