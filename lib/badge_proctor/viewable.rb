# Determines if a `Badge` resource can be viewed for a specific user
#
# Options include:
#   course:  Will verify the badge is for the course.
#   level:   Will only show students invisible badges earned for the specific
#            level. This is used for Rubric views to hide all invisible level
#            badges on unearned levels, even if the student earned the badge in
#            another context.
#
class BadgeProctor
  module Viewable
    include Base

    def viewable?(user, options={})
      return false if badge.nil?

      course = options[:course] || badge.course
      level = options[:level]
      badge_for_course?(course) &&
        (user.is_staff?(course) || badge_visible_by_student?(user,level))
    end

    private

    def badge_visible_by_student?(student, level=nil)
      badge.visible? || earned_badges_visible_by_student?(student, level)
    end

    def earned_badges_visible_by_student?(student, level=nil)
      if level
        EarnedBadge.where(student_id: student.id, badge_id: badge.id,
          level_id: level.id, student_visible: true).present?
      else
        EarnedBadge.where(student_id: student.id, badge_id: badge.id,
          student_visible: true).present?
      end
    end
  end
end
