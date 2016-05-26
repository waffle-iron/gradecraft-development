# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "submissions/new" do

  let(:presenter) { Submissions::NewPresenter.new({ course: @course, assignment_id: @assignment.id,
                                                 view_context: ActionController::Base.new.view_context })
                                               }

  before(:all) do
    @course = create(:course)
    @assignment = create(:assignment, course: @course)
    @submission = Submission.new
  end

  before(:each) do
    allow(view).to receive(:current_course).and_return(@course)
    allow(view).to receive(:presenter).and_return presenter
    allow(presenter.view_context).to receive(:points).and_return @assignment.point_total
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "Submit #{@assignment.name} (#{@assignment.point_total} points)", count: 1
  end
end
