class MultipliedGradebookExporter < GradebookExporter

  private

  def gradebook_columns(course)
    base_student_columns + doubled_assignment_name_columns(course)
  end

  def doubled_assignment_name_columns(course)
    course.assignments.collect do |assignment|
      [ assignment.name, assignment.name ]
    end.flatten
  end

  def student_data_for(student, course)
    # add the base column names
    student_data = base_student_methods.inject([]) do |memo, method|
      memo << student.send(method)
    end
    # TODO: we need to pre-fetch the course teams for this
    student_data << student.team_for_course(course).try(:name)

    # add the grades for the necessary assignments
    # TODO: improve the performance here
    course.assignments.inject(student_data) do |memo, assignment|
      grade = assignment.grade_for_student(student)
      if GradeProctor.new(grade).viewable?
        memo << grade.raw_score
        memo << grade.score
      else
        memo << ""
        memo << ""
      end
      memo
    end
  end
end
