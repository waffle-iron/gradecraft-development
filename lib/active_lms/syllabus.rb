require "active_support"
require_relative "syllabus/canvas_syllabus"

module ActiveLMS
  class Syllabus
    include ActiveSupport::Inflector

    attr_reader :provider

    def initialize(provider, access_token)
      klass = constantize("ActiveLMS::#{camelize(provider)}Syllabus")
      @provider = klass.new access_token
    rescue NameError
      raise InvalidProviderError.new(provider)
    end

    def course(id, &exception_handler)
      provider.course(id, &exception_handler)
    end

    def courses(&exception_handler)
      provider.courses(&exception_handler)
    end

    def assignment(course_id, assignment_id, &exception_handler)
      provider.assignment(course_id, assignment_id, &exception_handler)
    end

    def assignments(course_id, assignment_ids=nil, &exception_handler)
      provider.assignments(course_id, assignment_ids, &exception_handler)
    end

    def grades(course_id, assignment_ids, grade_ids=nil, &exception_handler)
      provider.grades(course_id, assignment_ids, grade_ids, &exception_handler)
    end

    def update_assignment(course_id, assignment_id, params)
      provider.update_assignment(course_id, assignment_id, params)
    end

    def user(id)
      provider.user(id)
    end
  end
end
