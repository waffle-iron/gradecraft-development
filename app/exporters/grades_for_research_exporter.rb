class GradesForResearchExporter

  def research_grades(course)
    CSV.generate do |csv|
      csv.add_row baseline_headers
      if course.grades.present?
        course.grades.each do |grade|
          csv.add_row grade_data(course, grade)
        end
      end
    end
  end

  private

  def baseline_headers
    ["Course ID", "Uniqname", "First Name", "Last Name", "GradeCraft ID",
      "Assignment Name", "Assignment ID", "Assignment Type",
      "Assignment Type Id", "Score", "Assignment Point Total",
      "Multiplied Score", "Predicted Score", "Text Feedback",
      "Submission ID", "Submission Creation Date", "Submission Updated Date",
      "Graded By", "Created At", "Updated At"]
  end

  def grade_data(course, grade)
    [course.id,
      grade.student.username,
      grade.student.first_name,
      grade.student.last_name,
      grade.student_id,
      grade.assignment.name,
      grade.assignment.id,
      grade.assignment.assignment_type.name,
      grade.assignment.assignment_type_id,
      grade.raw_score,
      grade.point_total,
      grade.score,
      predicted_points(grade),
      grade.feedback,
      (grade.submission_id || ""),
      (grade.submission.try(:created_at) || ""),
      (grade.submission.try(:updated_at) || ""),
      (grade.graded_by_id || ""),
      grade.created_at,
      grade.graded_at || ""]
  end

  def predicted_points(grade)
    prediction = PredictedEarnedGrade.where(
      student_id: grade.student.id, assignment_id: grade.assignment.id
    ).first.try(:predicted_points)
  end
end
