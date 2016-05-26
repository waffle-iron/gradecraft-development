# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "info/ungraded_submissions" do

  before(:all) do
    @course = create(:course)
    @assignment_types = [create(:assignment_type, course: @course, max_points: 1000)]
    @assignment = create(:assignment, assignment_type: @assignment_types[0])
    @student_1 = create(:user)
    @student_2 = create(:user)
    assign(:assignment_types, @assignment_types)
  end

  before(:each) do
    assign(:title, "Ungraded Assignment Submissions")
    allow(view).to receive(:current_course).and_return(@course)
    ungraded_submission_1 = create(:submission, student: @student_1, assignment: @assignment)
    ungraded_submission_2 = create(:submission, student: @student_2, assignment: @assignment)
    @ungraded_submissions = @assignment.submissions
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "Ungraded Assignment Submissions", count: 1
  end
end
