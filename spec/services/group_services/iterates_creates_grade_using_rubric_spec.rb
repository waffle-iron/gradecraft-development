require "light-service"
require "active_record_spec_helper"
require "./app/services/group_services/iterates_creates_grade_using_rubric"

describe Services::Actions::IteratesCreatesGradeUsingRubric do
  let(:world) { World.create.with(:course, :student, :assignment, :rubric, :criterion,
                                  :criterion_grade, :badge, :group) }
  let(:group_params) {{ "group_id" => world.group.id }}
  let(:raw_params) { RubricGradePUT.new(world).params.merge group_params }
  let(:user) { create :user }

  it "fails if the group is not found" do
    raw_params["group_id"] = 1000
    result = described_class.execute raw_params: raw_params, user: user
    expect(result.message).to eq("Unable to find group")
  end

  it "iterates over the students in group" do
    expect(Services::CreatesGradeUsingRubric).to \
      receive(:create).exactly(world.group.students.count).times.and_call_original
    described_class.execute raw_params: raw_params, user: user
  end

  it "adds the group id to the context" do
    result = described_class.execute raw_params: raw_params, user: user
    expect(result[:attributes]["group_id"]).to eq(world.group.id)
  end
end
