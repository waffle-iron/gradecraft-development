# encoding: utf-8
require "rails_spec_helper"

describe "api/badges/index" do
  before(:all) do
    @world = World.create
                  .create_course(badge_term: "baj")
                  .create_badge(description: "...")
    @badge = @world.badge
    @badges = [@badge]
  end

  before(:each) do
    allow(view).to receive(:current_course).and_return(@world.course)
    allow(view).to receive(:current_user).and_return(double(:user, is_staff?: false, id: 555))
  end

  it "responds with an array of badges" do
    render
    json = JSON.parse(response.body)
    expect(json["data"].length).to eq(1)
  end

  it "does not include invisible badges for students" do
    allow(@badge).to receive(:visible?).and_return(false)
    render
    json = JSON.parse(response.body)
    expect(json["data"].length).to eq(0)
  end

  it "does include invisible badges for staff" do
    allow(@badge).to receive(:visible?).and_return(false)
    allow(view).to receive(:current_user).and_return(double(:gsi, is_staff?: true))
    render
    json = JSON.parse(response.body)
    expect(json["data"].length).to eq(1)
  end

  it "adds the icon url to the badges" do
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["icon"]).to eq(@badge.icon.url)
  end

  it "adds is_a_condition to model" do
    allow(@badge).to receive(:is_a_condition?).and_return(true)
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["is_a_condition"]).to be_truthy
  end

  it "includes unlock keys when badge is an unlock condition" do
    assignment = create(:assignment)
    unlock_key = create(:unlock_condition,
                        unlockable: assignment, unlockable_type: "Assignment",
                        condition: @badge, condition_type: "Badge")
    @badge.reload
    render
    json = JSON.parse(response.body)
    expect(json["data"][0]["attributes"]["unlock_keys"]).to \
      eq(["#{assignment.name} is unlocked by #{unlock_key.condition_state} #{@badge.name}"])
  end

  it "renders term for badge, badges" do
    render
    json = JSON.parse(response.body)
    expect(json["meta"]["term_for_badge"]).to eq("baj")
    expect(json["meta"]["term_for_badges"]).to eq("bajs")
  end
end
