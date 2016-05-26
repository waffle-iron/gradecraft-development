# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "api/grade_scheme_elements/index" do
  before(:all) do
    @grade_scheme_element = create(:grade_scheme_element_high)
    @grade_scheme_elements = [@grade_scheme_element]
    @total_points = 10000
  end
  before(:each) do
    render
    @json = JSON.parse(response.body)
  end

  it "responds with total_points" do
    expect(@json["meta"]["total_points"]).to eq(10000)
  end

  it "responds with an array of grade_scheme_elements including name" do
    expect(@json["data"].length).to eq(1)
    expect(@json["data"][0]["attributes"]["name"]).to eq(@grade_scheme_element.name)
  end
end
