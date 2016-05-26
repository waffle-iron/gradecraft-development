# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "api/predicted_earned_challenges/index" do
  before(:all) do
    @course = create(:course, challenge_term: "tsallenze")
    @student = create(:user)
  end
  before(:each) do
    @challenge = create(:challenge, description: "...")
    @challenges = [@challenge]
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "responds with an array of challenges" do
    render
    @json = JSON.parse(response.body)
    expect(@json["data"].length).to eq(1)
  end

  it "does not include challenges invisible to students" do
    @challenge.update(visible: false)
    render
    @json = JSON.parse(response.body)
    expect(@json["data"].length).to eq(0)
  end

  it "adds the student predicted earned challenge info to the challenge" do
    allow(@challenge).to receive(:prediction).and_return({ id: 5, predicted_points: 3 })
    render
    @json = JSON.parse(response.body)
    expect(@json["data"][0]["attributes"]["prediction"]).to eq({ "id" => 5, "predicted_points" => 3 })
  end

  it "adds the score levels if present into the challenge" do
    csl = create(:challenge_score_level, challenge: @challenge)
    render
    @json = JSON.parse(response.body)
    expect(@json["data"][0]["attributes"]["score_levels"]).to eq([{"name" => csl.name, "value" => csl.value}])
  end

  it "adds the student grade into to the challenge" do
    allow(@challenge).to receive(:grade).and_return({ total_points: 555, score: 444, predicted_points: 444 })
    render
    @json = JSON.parse(response.body)
    expect(@json["data"][0]["attributes"]["grade"]).to eq({ "total_points" => 555, "score" => 444, "predicted_points" => 444 })
  end

  describe "passes boolean states for icons" do
    it "adds has_info to model" do
      @challenge.update(required: true)
      render
      @json = JSON.parse(response.body)
      expect(@json["data"][0]["attributes"]["has_info"]).to be_truthy
    end
  end

  it "renders term for challenges" do
    render
    @json = JSON.parse(response.body)
    expect(@json["meta"]["term_for_challenges"]).to eq("team tsallenzes")
  end

  it "includes update_challenges" do
    @update_challenges = true
    render
    @json = JSON.parse(response.body)
    expect(@json["meta"]["update_challenges"]).to be_truthy
  end
end
