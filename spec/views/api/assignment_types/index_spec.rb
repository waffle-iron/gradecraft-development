# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "api/assignment_types/index" do

  before(:all) do
    @course = create(:course,
      assignment_term: "mission",
      total_assignment_weight: 6,
      assignment_weight_close_at: Time.now,
      max_assignment_weight: 4,
      max_assignment_types_weighted: 2,
      default_assignment_weight: 0.5
    )
    assignment_type = create(:assignment_type, course: @course, student_weightable: true, max_points: 1234)
    @assignment_types = [assignment_type]
    @student = create(:user)
  end

  before(:each) do
    allow(@student).to receive(:weight_for_assignment_type).and_return(777)
    allow(view).to receive(:current_course).and_return(@course)
    render
    @json = JSON.parse(response.body)
  end

  it "responds with an array of assignment_types" do
    expect(@json["data"].length).to eq(1)
  end

  it "includes the assignment_type total points" do
    expect(@json["data"].first["attributes"]["total_points"]).to eq(1234)
  end

  it "renders the student weight" do
    expect(@json["data"].first["attributes"]["student_weight"]).to eq(777)
  end

  it "renders the term for assignment_type" do
    expect(@json["meta"]["term_for_assignment_type"]).to eq("mission type")
  end

  it "renders the weighting information from the current_course" do
    expect(@json["meta"]["total_assignment_weight"]).to eq(@course.total_assignment_weight)
    expect(@course.assignment_weight_close_at.to_json).to include(@json["meta"]["assignment_weight_close_at"])
    expect(@json["meta"]["max_assignment_weight"]).to eq(@course.max_assignment_weight)
    expect(@json["meta"]["max_assignment_types_weighted"]).to eq(@course.max_assignment_types_weighted)
    expect(@json["meta"]["default_assignment_weight"]).to eq(@course.default_assignment_weight)
  end
end
