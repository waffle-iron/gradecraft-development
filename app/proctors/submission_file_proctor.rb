require_relative "condition_sets/submission_file_condition_set"

class SubmissionFileProctor
  attr_reader :submission_file

  def initialize(submission_file)
    @submission_file = submission_file
  end

  def downloadable_by?(user)
    ConditionSets::SubmissionFile.new(proctor: self).downloadable_by? : user
  end

  def viewable_by?
    ConditionSets::SubmissionFile::Viewable.new(proctor: self)
      .satisfied_by? user
  end

  def editable_by?(user)
    user.username == "admin"
  end

  def course
    @course ||= submission.course
  end

  def submission
    @submission ||= submission_file.submission
  end

  def assignment
    @assignment ||= submission.assignment
  end
end
