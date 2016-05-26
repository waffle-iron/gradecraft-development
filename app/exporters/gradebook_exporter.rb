class GradebookExporter

  # gradebook spreadsheet export for course
  def gradebook(course)
    CSV.generate do |csv|
      csv << gradebook_columns(course)
      course.students.each do |student|
        csv << student_data_for(student, course)
      end
    end
  end

  private

  def base_student_columns
    ["First Name", "Last Name", "Email", "Username", "Team"]
  end

  def assignment_name_columns(course)
    course.assignments.collect(&:name)
  end

  def gradebook_columns(course)
    base_student_columns + assignment_name_columns(course)
  end

  def base_student_methods
    [:first_name, :last_name, :email, :username]
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
      score = GradeProctor.new(grade).viewable? ? grade.raw_score : ""
      memo << score
      memo
    end
  end
end
