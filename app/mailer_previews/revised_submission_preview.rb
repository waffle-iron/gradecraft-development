class RevisedSubmissionPreview
  def revised_submission
    submission = Submission.last
    professor = User.first
    NotificationMailer.revised_submission submission, professor
  end
end
