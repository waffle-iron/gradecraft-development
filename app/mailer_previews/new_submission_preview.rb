class NewSubmissionPreview
  def new_submission
    submission = Submission.last
    professor = User.first
    NotificationMailer.new_submission submission.id, professor
  end
end
