class GradeExportPreview
  def grade_export
    course = Course.first
    ExportsMailer.grade_export(
      course,
      user = User.first,
      course.assignments.to_csv
    )
  end
end
