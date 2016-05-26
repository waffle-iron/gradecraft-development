module PredictorData
  extend ActiveSupport::Concern

  def predictor_badges(student)
    current_course.badges.select(
      :id,
      :name,
      :description,
      :point_total,
      :visible,
      :visible_when_locked,
      :can_earn_multiple_times,
      :position,
      :updated_at,
      :icon
    ).map do |badge|
      prediction = badge.find_or_create_predicted_earned_badge(student.id)
      if current_user_is_student?
        badge.prediction = {
          id: prediction.id,
          predicted_times_earned: prediction.times_earned_including_actual
        }
        badge
      else
        badge.prediction = {
          id: prediction.id,
          predicted_times_earned: prediction.actual_times_earned
        }
        badge
      end
    end
  end

  def predictor_challenges(student)
    return [] unless challenge_conditions_met? student
    team = student.team_for_course(current_course)
    grades = team.challenge_grades

    current_course.challenges.select(
      :id,
      :name,
      :visible,
      :description,
      :point_total
    ).map do |challenge|
      prediction =
        challenge.find_or_create_predicted_earned_challenge(@student.id)
      if current_user_is_student?
        challenge.prediction = {
          id: prediction.id, predicted_points: prediction.predicted_points
        }
      else
        challenge.prediction = {
          id: prediction.id, predicted_points: 0
        }
      end

      grade = grades.where(challenge_id: challenge.id).first
      if grade.present? && grade.is_student_visible?
        challenge.grade = {
          score: grade.score,
        }
      else
        challenge.grade = {
          score: nil,
        }
      end
      challenge
    end
  end

  def predictor_assignment_types
    current_course.assignment_types
      .select(
        :course_id,
        :id,
        :name,
        :max_points,
        :description,
        :student_weightable,
        :position,
        :updated_at
      )
  end

  private

  def challenge_conditions_met?(student)
    current_course.challenges.present? &&
    student.team_for_course(current_course).present? &&
    current_course.add_team_score_to_student
  end
end
