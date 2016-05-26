class SuccessfulSubmissionPreview
  def successful_submission
    submission = Submission.last
    NotificationMailer.successful_submission submission
  end
end
