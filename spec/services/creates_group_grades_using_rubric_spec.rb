require "active_record_spec_helper"
require "./app/services/creates_group_grades_using_rubric"

describe Services::CreatesGroupGradesUsingRubric do
  let(:world) { World.create.with(:course, :student, :assignment, :rubric, :criterion,
                                  :criterion_grade, :badge, :group) }
  let(:group_params) {{ "group_id" => world.group.id }}
  let(:params) { RubricGradePUT.new(world).params.merge group_params }
  let(:user) { create :user }

  describe ".create" do
    it "interates through the students in a group" do
      expect(Services::Actions::IteratesCreatesGradeUsingRubric).to \
        receive(:execute).and_call_original
      described_class.create params, user
    end
  end
end
