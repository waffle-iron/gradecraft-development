class CriterionGradesExporter
  def export(course, rubric)
    CSV.generate do |csv|
      csv << gradebook_columns(rubric)
      course.students.each do |student|
        csv.add_row baseline_student_data(student, course) + earned_level_data(student, rubric)
      end
    end
  end

  private

  def base_student_columns
    ["First Name", "Last Name", "Email", "Username", "Team"]
  end

  def criterion_columns(rubric)
    rubric.criteria.ordered.collect(&:name)
  end

  def gradebook_columns(rubric)
    base_student_columns + criterion_columns(rubric)
  end

  def baseline_student_data(student, course)
    [ student.first_name, student.last_name, student.email, student.username,
      student.team_for_course(course).try(:name) ].freeze
  end

  def earned_level_data(student, rubric)
    level_data = []
    rubric.criteria.ordered.inject(level_data) do |memo, criterion|
      earned_level = criterion.criterion_grades.where(student: student).first
      memo << "#{earned_level.level.name}: #{earned_level.comments}"
    end
  end
end
