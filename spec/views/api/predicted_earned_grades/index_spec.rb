# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "assignments/predictor_data" do
  before(:all) do
    @course = create(:course, assignment_term: "mission", pass_term: "paz", fail_term: "fayl")
    @student = create(:user)
  end

  before(:each) do
    @assignment = create(:assignment, description: "...", course: @course)
    @assignments = PredictedAssignmentCollectionSerializer.new Assignment.where(id: @assignment.id), @student, @student
    allow(view).to receive(:current_course).and_return(@course)
    allow(view).to receive(:current_user).and_return(@student)
  end

  it "responds with an array of assignments" do
    render
    json = JSON.parse(response.body)
    expect(json["assignments"].length).to eq(1)
  end

  it "adds the predictor_display_type 'checkbox' to assignments" do
    allow_any_instance_of(Assignment).to receive(:points_predictor_display).and_return("Slider")
    render
    json = JSON.parse(response.body)
    expect(json["assignments"][0]["predictor_display_type"]).to eq("slider")
  end

  it "adds the predictor_display_type 'checkbox' to assignments" do
    render
    json = JSON.parse(response.body)
    expect(json["assignments"][0]["predictor_display_type"]).to eq("checkbox")
  end

  it "includes the current student grade with the assignment" do
    create :student_course_membership, user: @student, course: @assignment.course
    grade = create :grade, assignment: @assignment, student: @student,
      course: @assignment.course, pass_fail_status: "should not persist",
      raw_score: 1000, score: 1000, status: "Released"
    render
    json = JSON.parse(response.body)
    expect(json["assignments"][0]["grade"]).to eq(
      { "id" => grade.id,
        "final_points" => 1000,
        "score" => 1000,
        "is_excluded" => false
      })
  end

  it "includes the pass fail status with the grade when the assignment is pass fail" do
    create :student_course_membership, user: @student, course: @assignment.course
    grade = create :grade, assignment: @assignment, student: @student,
      course: @assignment.course, pass_fail_status: "passed", raw_score: 1000,
      score: 1000, status: "Released"
    @assignment.update(pass_fail: true)
    render
    json = JSON.parse(response.body)
    expect(json["assignments"][0]["grade"]).to eq(
      { "id" => grade.id,
        "pass_fail_status" => "passed",
        "final_points" => 1000,
        "score" => 1000,
        "is_excluded" => false
      })
  end

  it "does not include assignments with no points" do
    @assignment.update(point_total: 0)
    render
    json = JSON.parse(response.body)
    expect(json["assignments"].length).to eq(0)
  end

  it "does include pass/fail assignments with no points" do
    @assignment.update(point_total: 0, pass_fail: true)
    render
    json = JSON.parse(response.body)
    expect(json["assignments"].length).to eq(1)
  end

  it "does not include assignments invisible to students" do
    @assignment.update(visible: false)
    render
    json = JSON.parse(response.body)
    expect(json["assignments"].length).to eq(0)
  end

  it "not include assignments in predictor if include_in_predictor is false" do
    @assignment.update(include_in_predictor: false)
    render
    json = JSON.parse(response.body)
    expect(json["assignments"].length).to eq(0)
  end

  describe "passes boolean states for icons" do
    it "adds is_required to model" do
      @assignment.update(required: true)
      render
      json = JSON.parse(response.body)
      expect(json["assignments"][0]["is_required"]).to be_truthy
    end

    it "adds has_info to model" do
      render
      json = JSON.parse(response.body)
      expect(json["assignments"][0]["has_info"]).to be_truthy
    end

    it "adds is_late to model" do
      @assignment.update_attributes(accepts_submissions: true, due_at: 2.days.ago)
      render
      json = JSON.parse(response.body)
      expect(json["assignments"][0]["is_late"]).to eq true
    end

    it "adds is_locked to model" do
      allow_any_instance_of(Assignment).to \
        receive(:is_unlocked_for_student?).and_return(false)
      render
      json = JSON.parse(response.body)
      expect(json["assignments"][0]["is_locked"]).to eq true
    end

    it "adds has_been_unlocked to model" do
      allow_any_instance_of(Assignment).to \
        receive(:is_unlockable?).and_return(true)
      allow_any_instance_of(Assignment).to \
        receive(:is_unlocked_for_student?).and_return(true)
      render
      json = JSON.parse(response.body)
      expect(json["assignments"][0]["has_been_unlocked"]).to eq true
    end

    it "adds is_a_condition to model" do
      allow_any_instance_of(PredictedAssignmentSerializer).to \
        receive(:is_a_condition?).and_return(true)
      render
      json = JSON.parse(response.body)
      expect(json["assignments"][0]["is_a_condition"]).to be_truthy
    end

    it "adds is_earned_by_group to model" do
      allow_any_instance_of(Assignment).to \
        receive(:grade_scope).and_return("Group")
      render
      @json = JSON.parse(response.body)
      expect(@json["assignments"][0]["is_earned_by_group"]).to be_truthy
    end
  end

  it "includes unlock keys when assignment is an unlock condition" do
    badge = create(:badge)
    unlock_key = create(:unlock_condition, unlockable: badge, condition: @assignment)
    render
    json = JSON.parse(response.body)
    expect(json["assignments"][0]["unlock_keys"]).to eq(["#{badge.name} is unlocked by #{unlock_key.condition_state} #{@assignment.name}"])
  end

  it "includes unlock conditions when assignment is a unlockable" do
    badge = create(:badge)
    unlock_condition = create(:unlock_condition, unlockable: @assignment, unlockable_type: "Assignment", condition: badge, condition_type: "Badge")
    render
    json = JSON.parse(response.body)
    expect(json["assignments"][0]["unlock_conditions"]).to eq(["#{badge.name} must be #{unlock_condition.condition_state}"])
  end

  it "includes the assignment score levels" do
    asl = create(:assignment_score_level, assignment: @assignment)
    render
    json = JSON.parse(response.body)
    expect(json["assignments"][0]["score_levels"]).to eq([{"name" => asl.name, "value" => asl.value}])
  end

  it "renders term for assignments, pass, and fail" do
    render
    json = JSON.parse(response.body)
    expect(json["term_for_assignment"]).to eq("mission")
    expect(json["term_for_pass"]).to eq("paz")
    expect(json["term_for_fail"]).to eq("fayl")
  end
end
