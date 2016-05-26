# common methods for CRUD operations on a `Grade`
class GradeProctor
  module Base

    private

    def grade_for_course?(course)
      grade.course_id == course.id
    end

    def grade_for_user?(user)
      grade.student_id == user.id
    end
  end
end
