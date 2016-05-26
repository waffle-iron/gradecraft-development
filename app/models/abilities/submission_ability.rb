module SubmissionAbility
  def define_submission_abilities(user, course)
    can :manage, Submission do |submission|
      assignment = submission.assignment
      readable = false

      if submission.course_id == course.id
        if user.is_staff?(course)
          readable = true
        elsif !assignment.nil? && assignment.is_individual?
          readable = submission.student_id == user.id
        elsif !assignment.nil? && assignment.has_groups?
          group = user.group_for_assignment(assignment)
          readable = !group.nil? && group.id == submission.group_id
        end
      end

      readable
    end
  end
end
