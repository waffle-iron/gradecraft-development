class GroupNotifyPreview
  def group_notify
    group = Group.first
    @student = group.students.first
    NotificationMailer.group_notify group.id
  end
end
