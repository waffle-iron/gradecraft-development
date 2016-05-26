require "rails_spec_helper"
include CourseTerms

describe "submissions/show" do

  let(:presenter) { Submissions::ShowPresenter.new({ course: @course, id: @submission.id, assignment_id: @assignment.id, view_context: view_context }) }
  let(:view_context) { double(:view_context, points: "12,000") }

  before(:all) do
    @course = create(:course)
    @assignment = create(:assignment, course: @course)
    @student = create(:user)
    @course.users << @student
    @submission = create(:submission, course: @course, assignment: @assignment, student: @student)
  end

  before(:each) do
    allow(view).to receive(:current_course).and_return(@course)
    # stub path called in partial app/views/submissions/_buttons.haml
    allow(view).to receive(:assignment_submission_path).and_return("#")
    allow(view).to receive(:presenter).and_return presenter
  end

  it "renders successfully for an individual submission" do
    render
    assert_select "h3", text: "#{@student.first_name}'s #{@assignment.name} Submission (12,000 points)", count: 1
  end

  it "renders the submitted at date" do
    render
    assert_select "span.submission-date", text: "#{ @submission.submitted_at }", count: 1
  end
end
