module Toolkits
  module Models
    module AssignmentsToolkit
      def clear_rails_cache
        Rails.cache.clear
      end

      def create_doubles_with_ivars(*entities)
        entities.each do |entity|
          this_double = double(entity)
          instance_variable_set("@#{entity.to_s.underscore}", this_double)
        end
      end

      def setup_default_env
        @students = []
        @course = create(:course)
        @professor = create_professor_for_course # also adds professor to course
        @assignment = create_assignment_for_course # also creates @assignment_type
        @students += create_students_for_course(2)
        @team = create_team_and_add_students
      end

      # setup default submissions environment
      def setup_submissions_environment_with_users
        setup_default_env
        @submissions = create_submissions_for_students
      end

      # setup default submissions environment
      def setup_fileless_submissions_environment_with_users
        setup_default_env
        @submissions = create_fileless_submissions_for_students
      end

      # helper methods
      def create_student_for_course
        # return just one user and not a whole array
        # because arrays are for fools
        create_students_for_course(1).first
      end

      def create_students_for_course(total=1)
        (1..total).collect do |student_number|
          # sets instance variables as @student1, @student2 etc.
          n = student_number + @students.size
          student = create(:user)
          self.instance_variable_set("@student#{n}", student)
          enroll_student_in_active_course(student)
          student
        end
      end

      def create_students_with_names(*student_names)
        User.where(username: student_names.collect {|n| n.sub(/ /,".").downcase }).destroy_all
        student_names.inject([]) do |memo, name|
          # get an index for the @studentSOME# instance varible relative to the object's @students array
          # @student3, @student4 etc.
          n = memo.size + 1 + @students.size

          # create and name the student
          student = create(:user, first_name: name.split.first, last_name: name.split.last, username: name.sub(/ /,".").downcase)

          # set the instance variable '@studentSOME#'
          self.instance_variable_set("@student#{n}", student)

          # enroll the damn student in the durn course already
          enroll_student_in_active_course(student)

          # add the student to the memo so you can count it and don't have to use a durn tally
          memo << student
        end
      end

      def create_teamless_student_with_submission
        student = create_student_for_course
        grade = grade_student_for_active_assignment(student)
        create(:submission, grade: grade, student: student, assignment: @assignment)
      end

      def enroll_student_in_active_course(student)
        CourseMembership.create user_id: student[:id], course_id: @course[:id], role: "student"
      end

      def grade_student_for_active_assignment(student)
        create(:grade, assignment: @assignment, student: student, feedback: "good jorb!")
      end

      def create_submission_for_student(student)
        grade = grade_student_for_active_assignment(student)
        submission = create(:submission, grade: grade, student: student, assignment: @assignment, course: @course)
        submission
      end

      def create_submissions_for_students
        @students.collect do |student|
          grade = grade_student_for_active_assignment(student)
          submission = create(:submission, grade: grade, student: student, assignment: @assignment, course: @course)
          submission
        end
      end

      def create_fileless_submissions_for_students
        @students.collect do |student|
          grade = grade_student_for_active_assignment(student)
          submission = create(:empty_submission, grade: grade, student: student, assignment: @assignment, course: @course)
          submission
        end
      end

      def create_professor_for_course
        professor = create(:user)
        CourseMembership.create user_id: professor[:id], course_id: @course[:id], role: "professor"
        professor
      end

      def create_assignment_for_course
        @assignment_type = create(:assignment_type, course: @course)
        create(:assignment, assignment_type: @assignment_type, course: @course)
      end

      def create_team_and_add_students
        team = create(:team, course: @course)
        @students.each do |student|
          create(:team_membership, team: team, student: student)
        end
        team
      end
    end
  end
end
