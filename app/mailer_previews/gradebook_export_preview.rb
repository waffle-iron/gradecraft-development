class GradebookExportPreview
  def gradebook_export
    course = Course.first
    ExportsMailer.gradebook_export(
      course,
      User.first,
      "gradebook export", # export type
      course.assignments.to_csv
    )
  end
end
