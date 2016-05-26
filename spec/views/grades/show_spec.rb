# encoding: utf-8
require "rails_spec_helper"

describe "grades/show" do

  let(:presenter) { Assignments::Presenter.new({ assignment: @assignment, course: @course }) }

  before(:each) do
    @course = create(:course)
    @assignment = create(:assignment)
    @course.assignments << @assignment
    student = create(:user)
    student.courses << @course
    @grade = create(:grade, course: @course, assignment: @assignment, student: student)

    allow(view).to receive(:current_student).and_return(student)
    allow(view).to receive(:current_course).and_return(@course)
    allow(view).to receive(:presenter).and_return presenter
    allow(view).to receive(:term_for).and_return("Assignments")
  end

  describe "viewed by staff" do
    before(:each) do
      allow(view).to receive(:current_user_is_staff).and_return(true)
    end

    describe "with a raw score" do
      it "renders the points out of possible" do
        @grade.update(status: "Graded", raw_score: @assignment.point_total)
        render
        assert_select ".bold", text: "#{ points @grade.final_score } / #{ points @assignment.point_total } points earned", count: 1
      end
    end
  end

  describe "viewed by student" do
    before(:each) do
      allow(view).to receive(:current_user_is_staff).and_return(false)
    end
    it "renders successfully" do
      render
    end
  end
end
