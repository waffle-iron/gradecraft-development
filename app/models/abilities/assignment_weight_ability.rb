module AssignmentWeightAbility
  def define_assignment_weight_abilities(user, course)
    can :manage, AssignmentWeight, course_id: course.id, student_id: user.id
    can :manage, AssignmentWeight do |assignment_weight|
      assignment_weight.course == course &&
        user.is_staff?(assignment_weight.course)
    end
  end
end
