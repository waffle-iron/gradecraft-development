class AssignmentTypeExporter

  def export_scores(assignment_type, course, students)
    CSV.generate do |csv|
      csv.add_row baseline_headers + score_headers
      students.each do |student|
        csv.add_row baseline_student_data(student, course) + score_data(student, assignment_type)
      end
    end
  end

  def export_summary_scores(assignment_types, course, students)
    CSV.generate do |csv|
      csv.add_row baseline_headers + assignment_type_names(assignment_types)
      students.each do |student|
        csv.add_row baseline_student_data(student, course) + assignment_type_scores(student, assignment_types)
      end
    end
  end

  private

  def baseline_headers
    ["First Name", "Last Name", "Email", "Username", "Team"]
  end

  def score_headers
    ["Raw Score", "Score"]
  end

  def assignment_type_names(assignment_types)
    assignment_types.collect do |assignment_type|
      [ assignment_type.try(:name) ]
    end.flatten
  end

  def score_data(student, assignment_type)
    [ assignment_type.raw_score_for_student(student), assignment_type.score_for_student(student) ]
  end

  def baseline_student_data(student, course)
    [ student.first_name, student.last_name, student.email, student.username, student.team_for_course(course).try(:name) ].freeze
  end

  def assignment_type_scores(student, assignment_types)
    assignment_types.collect do |assignment_type|
      [ assignment_type.visible_score_for_student(student) ]
    end.flatten
  end
end
