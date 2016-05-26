namespace :grades do

  desc "Set all grades that have a status as being instructor_modified"

  task update_instructor_modified: :environment do
    puts "Setting grades as 'instructor_modified where a status exists..."
    total_updated = Grade.where("status is not null").update_all(instructor_modified: true)
    puts "Updated #{total_updated} grades with instructor_modified: true"
    puts "DONE"
  end

  desc "Update all of the graded_at dates to the updated_at for the grades"
  task update_graded_at: :environment do
    Grade.find_each(batch_size: 500) { |g| g.update_column(:graded_at, g.graded_at) }
  end

  desc "Transfer the predictions off existing grades"
  task transfer_predictions: :environment do
    Grade.where("predicted_score > 0").each do |grade|
      prediction = PredictedEarnedGrade.find_or_create_by(
        assignment_id: grade.assignment.id,
        student_id: grade.student.id
      )
      prediction.predicted_points = grade.predicted_score
      prediction.save
    end
  end
end
