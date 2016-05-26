# encoding: utf-8
require "rails_spec_helper"

describe "students/syllabus/_assignments" do

  let(:user) { double(:user, is_student?: true) }
  let(:view_context) { double(:view_context, current_user: user) }
  let(:presenter) { Students::SyllabusPresenter.new({ student: @student,
    course: @course, assignment_types: @assignment_types,
    view_context: view_context }) }

  before(:each) do
    @course = create(:course)
    @assignment_type_1 = create(:assignment_type, course: @course, max_points: 1000)
    @assignment_type_2 = create(:assignment_type, course: @course, max_points: 1000)
    @assignment = create(:assignment, assignment_type: @assignment_type_1)
    @course.assignment_types << [@assignment_type_1, @assignment_type_2]
    @assignment_types = @course.assignment_types
    @course.assignments << @assignment
    @student = create(:user)
    assign(:assignment_types, @assignment_types)
    allow(view).to receive(:current_course).and_return(@course)
    allow(view).to receive(:current_student).and_return(@student)
    allow(view).to receive(:presenter).and_return presenter
  end

  describe "as student" do
    before(:each) do
      allow(view).to receive(:current_student).and_return(@student)
    end

    it "does not render instructor menu" do
      render
      assert_select "li", text: "Grade", count: 0
    end

    it "renders when assignment is student_logged" do
      @assignment.update(student_logged: true)
      allow_any_instance_of(Assignment).to receive(:open?).and_return(true)
      allow(view).to receive(:current_user_is_student?).and_return(true)
      render
    end

    it "renders with team_challenges and team_score_average" do
      @course.update(team_challenges: true)
      @course.update(team_score_average: true)
      render
    end

    describe "when an assignment has points" do

      it "renders the points possible when grade is not released" do
        render
        assert_select "td", text: "#{points @assignment.point_total} points possible", count: 1
      end

      it "renders the points out of points possible when the grade is released for assignment" do
        @assignment.update(release_necessary: false)
        @grade = create(:grade, course: @course, assignment: @assignment, student: @student, raw_score: @assignment.point_total, status: "Graded")

        # To verify we have satisfied the released condition:
        expect(@student.grade_released_for_assignment?(@assignment)).to be_truthy
        render
        assert_select "td" do
          assert_select "div", text: "#{ points @grade.score } / #{points @grade.point_total} points earned", count: 1
        end
      end
    end

    describe "when an assignment is pass fail" do

      before(:each) do
        @assignment.update(pass_fail: true)
      end

      it "renders Pass/Fail in the points possible field when grade is not released" do
        render
        assert_select "td", text: "Pass/Fail", count: 1
      end

      it "renders Pass or Fail in the points possible field when a grade is released for assignment" do
        @grade = create(:grade, course: @course, assignment: @assignment, student: @student, pass_fail_status: "Pass", status: "Graded")

        # To verify we have satisfied the released condition:
        expect(@student.grade_released_for_assignment?(@assignment)).to be_truthy

        render
        assert_select "td" do
          assert_select "div", text: "Pass", count: 1
        end
      end
    end

    it "shows the description if it's present" do
      @assignment_type_1.update(description: "Tabula Rasa")
      @assignment_type_1.save
      render
      assert_select "p", text: "Tabula Rasa", count: 1
    end

    it "highlights assignments that are required" do
      @assignment.required = true
      @assignment.save
      render
      assert_select "i.fa-exclamation-circle", count: 1
    end

    it "shows the assignment submission if present" do
      @assignment.update(accepts_submissions: true)
      @submission = create(:submission, course: @course, assignment: @assignment, student: @student)
      render
      assert_select "a", text: "See Submission", count: 1
    end

    it "shows the due date if it's in the future" do
      @assignment.update(due_at: 2.days.from_now)
      render
      assert_select "span", text: "#{(2.days.from_now).strftime("%A, %b %d, %l:%M%p")}", count: 1
    end

    it "shows a button to see more results if the grade is released" do
      create(:grade, course: @course, assignment: @assignment, student: @student, raw_score: 2000, status: "Released")
      render
      assert_select "a", text: "See Grade", count: 1
    end

    it "shows a button to see the group if a group exists" do
      @assignment.update(grade_scope: "Group")
      @group = create(:group, course: @course)
      @assignment.groups << @group
      @group.students << @student
      allow(view).to receive(:term_for).and_return("Group")
      render
      assert_select "a", text: "See Group", count: 1
    end

    it "shows a button to see the group submission if one is present" do
      @assignment.update(accepts_submissions: true)
      @assignment.update(grade_scope: "Group")
      @group = create(:group, course: @course)
      @assignment.groups << @group
      @group.students << @student
      @submission = create(:submission, course: @course, assignment: @assignment, group: @group)
      render
      assert_select "a", text: "See Submission", count: 1
    end

    it "shows a button to create a group if no group is present" do
      @assignment.update(grade_scope: "Group")
      allow(view).to receive(:term_for).and_return("Group")
      render
      assert_select "a", text: "Create a Group", count: 1
    end

  end

  describe "as faculty" do
    it "renders the instructor grade managment menu" do
      allow(view).to receive(:current_user_is_staff?).and_return(true)
      allow(view).to receive(:term_for).and_return("custom_term")
      assign(:students, [@student])
      assign(:grades, {@student.id => nil})
      render
      assert_select "li", text: "Grade", count: 1
    end

    it "shows a button to edit a grade for an assignment if one is present" do
      allow(view).to receive(:current_user_is_staff?).and_return(true)
      allow(view).to receive(:term_for).and_return("custom_term")
      assign(:students, [@student])
      create(:grade, course: @course, instructor_modified: true, assignment: @assignment, student: @student, raw_score: 2000, status: "Released")
      render
      assert_select "a", text: "Edit Grade", count: 1
    end

    it "shows a button to see their submission if one is present" do
      allow(view).to receive(:current_user_is_staff?).and_return(true)
      allow(view).to receive(:term_for).and_return("custom_term")
      assign(:students, [@student])
      @assignment.update(accepts_submissions: true)
      @submission = create(:submission, course: @course, assignment: @assignment, student: @student)
      render
      assert_select "a", text: "See Submission", count: 1
    end
  end
end
