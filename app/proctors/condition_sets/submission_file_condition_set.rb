require "proctor"

module ConditionSets
  module SubmissionFile
    class Downloadable
      attr_accessor :group

      # this uses the resources on the proctor rather than defining them here
      defer_to_proctor :submission, :assignment, :course, :submission_file

      def initialize(proctor:)
        @proctor = proctor
      end

      def downloadable_by?(user)
        @user = user

        user_is_staff_for_course? || (submission_matches_course? &&
        user_owns_submission? && user_has_group_for_assignment? &&
        user_group_owns_submission)
      end

      def submission_matches_course?
        submission.course_id == course.id
      end

      def user_is_staff_for_course?
        user.is_staff? course
      end

      def assignment_present?
        !assignment.nil?
      end

      def user_owns_submission?
        return true if assignment.is_individual?
        submission.student_id == user.id
      end

      def user_has_group_for_assignment?
        return true unless assignment.has_groups?
        user.group_for_assignment(assignment)
      end

      def user_group_owns_submission?
        return true unless assignment.has_groups?
        group.id == submission.group_id
      end
    end
  end
end
