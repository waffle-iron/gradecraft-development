module AssignmentTypeWeightAbility
  def define_assignment_type_weight_abilities(user, course)
    can :manage, AssignmentTypeWeight, course_id: course.id, student_id: user.id
    can :manage, AssignmentTypeWeight do |assignment_weight|
      assignment_weight.course == course &&
        user.is_staff?(assignment_weight.course)
    end
  end
end
