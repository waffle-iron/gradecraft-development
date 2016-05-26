module GradeAbility
  def define_grade_abilities(user, course)
    can :read, Grade do |grade|
      GradeProctor.new(grade).viewable? user: user, course: course
    end

    can :update, Grade do |grade, options|
      GradeProctor.new(grade).updatable? (options || {})
        .merge({ user: user, course: course })
    end

    can :destroy, Grade do |grade, options|
      GradeProctor.new(grade).destroyable? (options || {})
        .merge({ user: user, course: course })
    end
  end
end
