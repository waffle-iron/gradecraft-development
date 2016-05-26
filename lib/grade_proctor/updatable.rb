# Determines if a `Grade` resource can be updated by a user. If no user is
# supplied in the options, it will default to the Grade's student.
#
# Options include:
#   course:  Will verify the grade is for the course
#   user:    Determines permissions for supplied user rather than the
#            grade's student
#
class GradeProctor
  module Updatable
    include Base

    def updatable?(options={})
      return false if grade.nil?

      user = user_from_options(options)
      course = grade_from_options(options)
      student_logged = student_logged_from_options(options)

      grade_for_course?(course) &&
        (user.is_staff?(course) ||
          (grade_for_user?(user) && (!student_logged ||
                                     grade.assignment.student_logged?)))
    end

    private

    def grade_from_options(options)
      options[:course] || grade.course
    end

    def student_logged_from_options(options)
      student_logged = true
      unless options[:student_logged].nil?
        student_logged = options[:student_logged]
      end
      student_logged
    end

    def user_from_options(options)
      options[:user] || grade.student
    end
  end
end
