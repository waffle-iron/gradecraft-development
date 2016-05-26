class GradeReleasedPreview
  def grade_released
    grade = Grade.last
    NotificationMailer.grade_released grade.id
  end
end
