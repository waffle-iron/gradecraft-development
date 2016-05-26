# Earned Level Badges are EarnedBadges that are earned on a specific level of a
# a rubric criteria. They are treated uniquely here to allow for
# future services that build EarnedBadges for other associations
# (submission, assignment, etc.)

module Services
  module Actions
    class BuildsEarnedLevelBadges
      extend LightService::Action

      expects :raw_params
      expects :student
      expects :assignment
      expects :student_visible_status

      promises :earned_level_badges

      # Returns an empty array if no level_badges in raw_params
      # expects: "level_badges" => [{ "badge_id"=>1, "level_id"=>1 },..]
      executed do |context|
        if context[:raw_params]["level_badges"].nil?
          context[:earned_level_badges] = []
        else
          context[:earned_level_badges] = new_earned_level_badges(
            context[:assignment],
            context[:student],
            !context[:student_visible_status].nil?,
            context[:raw_params]["level_badges"]
          )
        end
      end

      class << self
        private

        def new_earned_level_badges(assignment, student, visible_status, level_badges_params)
          destroy_exisiting_earned_badges(student.id, assignment.id)
          level_badges_params.collect do |params|
            level_badge = LevelBadge.where(badge_id: params["badge_id"], level_id: params["level_id"]).first
            EarnedBadge.new(course_id: assignment.course.id, assignment_id: assignment.id,
                            student_id: student.id, student_visible: visible_status,
                            badge_id: level_badge.badge.id, level_id: level_badge.level.id,
                            score: level_badge.badge.point_total)
          end
        end

        # I am adding this back in for now to handle all rubric update scenarios:
        #   1. If this is a rubric grading resubmission, we don't want to re-award a badge
        #   2. When a badge cannot be earned multiple times, duplicates will also cause an error on save
        #   3. More than one instance of a badge can be associated with a level, all instances are
        #      passed in the params.
        #
        # This should be handled better because:
        #   1. Level badges to award should not be accepted blindly from and API call, they should be determined through
        #      backend logic and current earnable badges in the database
        #   2. Currently there is a (race?) condition that causes badges to sometimes not load in the front end, in which
        #      case this will also mean badges that should be awarded will be lost.
        #   3. This is terrible for performace reasons, and won't allow us to track history through existing models.
        def destroy_exisiting_earned_badges(student_id, assignment_id)
          EarnedBadge.where(student_id: student_id, assignment_id: assignment_id).destroy_all
        end
      end
    end
  end
end
