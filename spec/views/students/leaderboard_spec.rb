require "rails_spec_helper"

describe "students/leaderboard" do
  include CourseTerms

  let(:course) { create :course }
  let(:presenter) { Students::LeaderboardPresenter.new(course: course) }

  before(:each) do
    @students = course.students
    assign(:title, "Leaderboard")
    allow(view).to receive(:current_course).and_return(course)
    allow(view).to receive(:presenter).and_return presenter
  end

  it "renders successfully" do
    render
    assert_select "h3", text: "Leaderboard", count: 1
  end

end
