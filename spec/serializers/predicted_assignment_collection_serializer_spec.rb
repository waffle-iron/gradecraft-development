require "active_record_spec_helper"
require "./app/serializers/predicted_assignment_collection_serializer"

describe PredictedAssignmentCollectionSerializer do
  let(:assignment1) { create :assignment }
  let(:assignment2) { create :assignment }
  let(:assignments) { Assignment.where(id: [assignment1.id, assignment2.id]) }
  let(:user) { double(:user) }
  let(:other_user) { double(:other_user) }

  describe "#initialize" do
    it "requires assignments and a user as the context" do
      subject = described_class.new assignments, user, user
      expect(subject.assignments.size).to eq assignments.size
      expect(subject.current_user).to eq user
    end

    it "plucks the assignment fields it exposes" do
      subject = described_class.new assignments, user, user
      assignment = subject.assignments.first
      [:accepts_submissions,
       :accepts_submissions_until,
       :assignment_type_id,
       :description,
       :due_at,
       :grade_scope,
       :id,
       :include_in_predictor,
       :name,
       :pass_fail,
       :point_total,
       :position,
       :required,
       :threshold_points,
       :use_rubric,
       :visible,
       :visible_when_locked].each do |attribute|
         expect(assignment).to respond_to attribute
       end
    end
  end

  describe "#each" do
    it "enumerates over the assignments and creates predicted assignments" do
      subject = described_class.new assignments, user, user
      subject.each do |assignment|
        expect(assignment).to be_instance_of PredictedAssignmentSerializer
      end
    end
  end

  describe "#[]" do
    it "can be indexed" do
      subject = described_class.new assignments, user, user
      expect(subject[0]).to be_an_instance_of PredictedAssignmentSerializer
      expect(subject[0].id).to eq assignments[0].id
    end
  end

  describe "permissions" do
    it "allows updates when current_user is same as student" do
      subject = described_class.new assignments, user, user
      expect(subject.permission_to_update?).to be_truthy
    end

    it "doens't allow updates when current user is other than student" do
      subject = described_class.new assignments, other_user, user
      expect(subject.permission_to_update?).to be_falsey
    end
  end
end
