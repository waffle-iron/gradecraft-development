class AddPredictedEarnedGrades < ActiveRecord::Migration
  def change
    create_table :predicted_earned_grades do |t|
      t.integer :assignment_id
      t.integer :student_id
      t.integer :predicted_points, default: 0
      t.timestamps
    end

    rename_column :predicted_earned_challenges, :points_earned, :predicted_points
    rename_column :predicted_earned_badges, :times_earned, :predicted_times_earned

    add_index :predicted_earned_grades, [:assignment_id, :student_id], unique: true, :name => 'index_predidcted_grade_on_student_assignment'
    add_index :predicted_earned_challenges, [:challenge_id, :student_id], unique: true, :name => 'index_predidcted_challenge_on_student_challenge'
    add_index :predicted_earned_badges, [:badge_id, :student_id], unique: true, :name => 'index_predidcted_badge_on_student_badge'
  end
end

