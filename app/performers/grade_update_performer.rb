class GradeUpdatePerformer < ResqueJob::Performer
  def setup
    @grade = fetch_grade_with_assignment
  end

  # perform() attributes assigned to @attrs in the ResqueJob::Base class
  def do_the_work
    require_save_scores_success
    require_notify_released_success
  end

  protected

  def require_save_scores_success
    require_success(save_scores_messages) do
      @grade.cache_student_and_team_scores
    end
  end

  def require_notify_released_success
    if @grade.assignment.notify_released? && GradeProctor.new(@grade).viewable?
      require_success(notify_released_messages, max_result_size: 200) { notify_grade_released }
    end
  end

  def save_scores_messages
    {
      success: "Student and team scores saved successfully for grade ##{@grade.id}",
      failure: "Student and team scores failed to save for grade ##{@grade.id}"
    }
  end

  def notify_released_messages
    {
      success: "Successfully sent notification of grade release.",
      failure: "Failed to send grade release notification."
    }
  end

  def fetch_grade_with_assignment
    Grade.where(id: @attrs[:grade_id]).includes(:assignment).load.first
    # Grade.find(@attrs[:grade_id])
  end

  def notify_grade_released
    NotificationMailer.grade_released(@grade.id).deliver_now
  end
end
