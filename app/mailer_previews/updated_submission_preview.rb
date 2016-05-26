class UpdatedSubmissionPreview
  def updated_submission
    submission = Submission.last
    NotificationMailer.updated_submission submission
  end
end
