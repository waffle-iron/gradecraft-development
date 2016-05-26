require "rails_spec_helper"
include CourseTerms

describe "submissions/edit" do

  let(:presenter) { Submissions::EditPresenter.new({ course: @course, id: @submission.id, assignment_id: @assignment.id,
                                                  view_context: view_context })
                                                }
  let(:view_context) { double(:view_context, current_user: @student) }

  before(:all) do
    @course = create(:course)
    @assignment = create(:assignment, course: @course)
    @student = create(:user)
    @course.users << @student
    @submission = create(:submission, course: @course, student: @student, assignment: @assignment)
  end

  before(:each) do
    allow(view).to receive(:current_course).and_return(@course)
    allow(view).to receive(:presenter).and_return presenter
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "Editing My Submission for #{@assignment.name}", count: 1
  end

end

