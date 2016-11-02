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

    def course(id)
      provider.course(id)
    end

    def courses
      provider.courses
    end

    def assignment(course_id, assignment_id)
      provider.assignment(course_id, assignment_id)
    end

    def assignments(course_id, assignment_ids=nil)
      provider.assignments(course_id, assignment_ids)
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
