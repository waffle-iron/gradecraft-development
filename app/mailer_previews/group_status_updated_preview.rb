class GroupStatusUpdatedPreview
  def group_status_updated
    group = Group.first
    @student = group.students.first
    NotificationMailer.group_status_updated group.id
  end
end
