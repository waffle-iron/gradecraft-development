require "rails_spec_helper"

describe Rubric do

  describe "validations" do
    let(:rubric) { build :rubric}

    it "is valid with an assignment" do
      expect(rubric).to be_valid
    end

    it "is invalid without an assignment" do
      rubric.assignment = nil
      expect(rubric).to be_invalid
    end
  end

  describe "#copy" do
    let(:rubric) { build :rubric }
    subject { rubric.copy }

    it "copies the criteria" do
      rubric.save
      rubric.criteria.create max_points: 10_000, name: "Repeatability", order: 1
      expect(subject.criteria.size).to eq 1
      expect(subject.criteria.map(&:rubric_id)).to eq [subject.id]
    end
  end

  describe "#max_level_count" do
    let(:rubric) { build :rubric }

    it "returns the maximum number of levels present for any criterion" do
      criterion_1 = create(:criterion, rubric: rubric)
      criterion_2 = create(:criterion, rubric: rubric)
      level_1 = create(:level, criterion: criterion_1)
      level_2 = create(:level, criterion: criterion_1)
      level_3 = create(:level, criterion: criterion_1)

      # count is the number created + the zero credit and the max credit
      expect(rubric.max_level_count).to eq(5)
    end
  end

  describe "#designed?" do
    let(:rubric) { build :rubric }

    it "returns true if criteria are present" do
      criterion = create(:criterion, rubric: rubric)
      expect(rubric.designed?).to eq(true)
    end

    it "returns false if criteria are not present" do
      expect(rubric.designed?).to eq(false)
    end
  end
end
