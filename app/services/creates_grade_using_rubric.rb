require "light-service"
require_relative "creates_criterion_grade/adds_grade_id_to_criterion_grades"
require_relative "creates_criterion_grade/builds_criterion_grades"
require_relative "creates_criterion_grade/builds_earned_level_badges"
require_relative "creates_criterion_grade/saves_criterion_grades"
require_relative "creates_criterion_grade/saves_earned_level_badges"
require_relative "creates_grade/verifies_assignment_student"
require_relative "creates_grade/associates_submission_with_grade"
require_relative "creates_grade/builds_grade"
require_relative "creates_grade/marks_as_graded"
require_relative "creates_grade/runs_grade_updater_job"
require_relative "creates_grade/saves_grade"

module Services
  class CreatesGradeUsingRubric
    extend LightService::Organizer

    aliases raw_params: :attributes

    def self.create(raw_params, graded_by_id)
      with(raw_params: raw_params, graded_by_id: graded_by_id)
        .reduce(
          Actions::VerifiesAssignmentStudent,
          Actions::BuildsCriterionGrades,
          Actions::BuildsGrade,
          Actions::AssociatesSubmissionWithGrade,
          Actions::MarksAsGraded,
          Actions::SavesGrade,
          Actions::AddsGradeIdToCriterionGrades,
          Actions::SavesCriterionGrades,
          Actions::BuildsEarnedLevelBadges,
          Actions::SavesEarnedLevelBadges,
          Actions::RunsGradeUpdaterJob
        )
    end
  end
end
