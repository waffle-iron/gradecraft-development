# Determines if a `Grade` resource can be viewed by a user. If no user is
# supplied in the options, it will default to the Grade's student.
#
# Options include:
#   course:  Will verify the grade is for the course
#   user:    Determines permissions for supplied user rather than the
#            grade's student
#
class GradeProctor
  module Viewable
    include Base

    def viewable?(options={})
      return false if grade.nil?

      user = options[:user] || grade.student
      course = options[:course] || grade.course

      grade_for_course?(course) &&
        (user.is_staff?(course) ||
          (grade_for_user?(user) && grade_visible_by_student?))
    end

    private

    def grade_visible_by_student?
      grade.is_released? ||
        (grade.is_graded? && !grade.assignment.release_necessary?)
    end
  end
end
