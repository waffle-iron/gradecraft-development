require "rails_spec_helper"

describe Criterion do
  subject { build(:criterion) }

  describe "validations" do
    it "is valid with max_points, name, and order" do
      expect(subject).to be_valid
    end

    it "is invalid without name" do
      subject.name = nil
      expect(subject).to be_invalid
    end

    it "is invalid without order" do
      subject.order = nil
      expect(subject).to be_invalid
    end
  end

  describe "#update_meets_expectations!" do
    before do
      subject.save
      subject.levels.first.update_attributes(meets_expectations: true)
    end

    it "manages setting a new level as 'meets expectations'" do
      subject.update_meets_expectations!(subject.levels.last, true)
      expect(subject.levels.first.reload.meets_expectations).to eq(false)
      expect(subject.levels.last.reload.meets_expectations).to eq(true)
      expect(subject.reload.meets_expectations_level_id).to eq(
        subject.levels.last.id
      )
      expect(subject.meets_expectations_points).to eq(
        subject.levels.last.points
      )
    end

    it "manages removing all 'meets expectations'" do
      subject.update_meets_expectations!(subject.levels.first, false)
      expect(subject.levels.first.reload.meets_expectations).to eq(false)
      expect(subject.reload.meets_expectations_level_id).to eq(nil)
      expect(subject.meets_expectations_points).to eq(0)
    end
  end

  describe "#copy" do
    let(:criterion) { build :criterion }
    subject { criterion.copy }

    it "sets the default levels to false" do
      expect(subject.add_default_levels).to eq false
    end

    it "saves the copy if the criterion is copied" do
      criterion.save
      expect(subject).to_not be_new_record
    end

    it "copies the levels" do
      criterion.save
      expect(subject.levels.count).to eq 2 # default levels already there
      expect(subject.levels.map(&:criterion_id)).to eq [subject.id, subject.id]
    end
  end

  describe "#comments_for" do

    it "returns comments for student" do
      subject.save
      grade = create :criterion_grade, criterion: subject, comments: "xo"
      expect(subject.comments_for(grade.student.id)).to eq("xo")
    end

    it "returns nil when no associated grade" do
      expect(subject.comments_for(0)).to eq(nil)
    end
  end

  context "creation" do
    context "criterion is flagged as duplicated" do
      it "should not create levels" do
        subject.add_default_levels = false
        subject.save
        expect(subject.levels.count).to eq(0)
      end
    end

    context "criterion isn't flagged as duplicated" do
      it "should create levels" do
        subject.add_default_levels = true
        subject.save
        expect(subject.levels.count).to eq(2)
      end
    end

    context "default" do
      it "should create default levels" do
        subject = create(:criterion)
        expect(subject.levels.count).to eq(2)
      end
    end
  end
end
