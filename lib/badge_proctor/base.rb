# common methods for CRUD operations on a `Grade`
class BadgeProctor
  module Base

    private

    def badge_for_course?(course)
      badge.course_id == course.id
    end

    def badge_earned_by_user?(user)
      badge.student_id == user.id
    end
  end
end
