require "csv"

class CSVGradeImporter
  attr_reader :successful, :unsuccessful, :unchanged
  attr_accessor :file

  def initialize(file)
    @file = file
    @successful = []
    @unsuccessful = []
    @unchanged = []
  end

  def import(course=nil, assignment=nil, grader=nil)
    if file
      if course && assignment
        students = course.students
        CSV.foreach(file, headers: true) do |csv|
          row = GradeRow.new csv

          student = find_student(row, students)
          if student.nil?
            append_unsuccessful row, "Student not found in course"
            next
          end
          if !row.has_grade?
            append_unsuccessful row, "Grade not specified"
            next
          end

          grade = assignment.grades.where(student_id: student.id).first
          if row.update_grade? grade
            grade = update_grade row, grade, grader
            report row, grade
          elsif grade.present?
            unchanged << grade
          elsif grade.nil?
            grade = create_grade row, assignment, grader, student
            report row, grade
          end
        end
      end
    end

    self
  end

  private

  def append_unsuccessful(row, errors)
    unsuccessful << { data: row.to_s, errors: errors }
  end

  def assign_grade(row, grade, grader)
    grade.raw_points = row.grade
    grade.feedback = row.feedback
    grade.status = "Graded" if grade.status.nil?
    grade.graded_by_id = grader.id unless grader.nil?
    grade.graded_at = DateTime.now
  end

  def create_grade(row, assignment, grader, student)
    assignment.grades.create do |grade|
      grade.student_id = student.id
      assign_grade row, grade, grader
    end
  end

  def update_grade(row, grade, grader)
    assign_grade row, grade, grader
    grade.save
    grade
  end

  def find_student(row, students)
    message = row.identifier =~ /@/ ? :email : :username
    students.find do |student|
      student.public_send(message).downcase == row.identifier
    end
  end

  def report(row, grade)
    if grade.valid?
      successful << grade
    else
      append_unsuccessful row, grade.errors.full_messages.join(", ")
    end
  end

  class GradeRow
    include QuoteHelper

    attr_reader :data

    def identifier
      remove_smart_quotes(data[2]).downcase if data[2].present?
    end

    def feedback
      remove_smart_quotes data[4]
    end

    def grade
      remove_smart_quotes(data[3]).to_i if data[3].present?
    end

    def has_grade?
      grade.present?
    end

    def update_grade?(grade)
      grade.present? &&
        (grade.raw_points != self.grade || grade.feedback != feedback)
    end

    def initialize(data)
      @data = data
    end

    def to_s
      data.to_s
    end
  end
end
