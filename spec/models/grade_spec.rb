require "active_record_spec_helper"
require "toolkits/historical_toolkit"
require "toolkits/sanitization_toolkit"
require_relative "../support/uni_mock/rails"

describe Grade do
  include UniMock::StubRails

  before { stub_env "development" }

  subject { build(:grade) }

  describe "constants" do
    describe "STATUSES" do
      it "returns an array of all the status values" do
        expect(described_class::STATUSES).to eq ["In Progress", "Graded", "Released"]
      end
    end

    describe "UNRELEASED_STATUSES" do
      it "returns an array of all the status values" do
        expect(described_class::UNRELEASED_STATUSES).to eq ["In Progress", "Graded"]
      end
    end
  end

  describe "validations" do
    it "is valid with an assignment, student, assignment_type, and course" do
      expect(subject).to be_valid
    end

    it "is invalid without an assignment" do
      subject.assignment = nil
      expect{ subject.save! }.to raise_error Module::DelegationError
    end

    it "is invalid without a student" do
      subject.student = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:student]).to include "can't be blank"
    end

    it "is invalid without a course" do
      subject.assignment.course = nil
      subject.course = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:course]).to include "can't be blank"
    end

    it "is invalid without an assignment type" do
      subject.assignment.assignment_type = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:assignment_type]).to include "can't be blank"
    end

    it "does not allow duplicate grades per student" do
      subject.save!
      another_grade = build(:grade, course: subject.course, assignment: subject.assignment, student: subject.student)
      expect(another_grade).to_not be_valid
      expect(another_grade.errors[:assignment_id]).to include "has already been taken"
    end
  end

  it_behaves_like "a historical model", :grade, raw_points: 1234
  it_behaves_like "a model that needs sanitization", :feedback

  describe "#squish_history!", versioning: true do
    it "squishes two previous changes into one" do
      subject.save!
      subject.update_attributes raw_points: 13_000
      subject.squish_history!
      subject.update_attributes feedback: "This is a change"
      subject.squish_history!
      expect(subject.versions.count).to eq 2
      expect(subject.versions.last.changeset).to have_key :feedback
      expect(subject.versions.last.changeset).to have_key :raw_points
    end
  end

  describe "#clear_grade!" do
    subject  { create :released_grade, feedback: "You rock", feedback_read: true,
               feedback_read_at: DateTime.now, feedback_reviewed: true,
               feedback_reviewed_at: DateTime.now,
               graded_at: DateTime.now, graded_by_id: 123 }

    it "clears the raw points" do
      subject.clear_grade!

      expect(subject.raw_points).to be_nil
    end

    it "clears the adjustment" do
      subject.clear_grade!

      expect(subject.adjustment_points).to eq 0
      expect(subject.adjustment_points_feedback).to be_nil
    end

    it "clears the status" do
      subject.clear_grade!

      expect(subject.status).to be_nil
    end

    it "clears the feedback" do
      subject.clear_grade!

      expect(subject.feedback).to be_empty
      expect(subject.feedback_read_at).to be_nil
      expect(subject.feedback_reviewed_at).to be_nil
      expect(subject.feedback_read).to eq false
      expect(subject.feedback_reviewed).to eq false
    end

    it "removes any indication that it's been graded" do
      subject.clear_grade!

      expect(subject.graded_at).to be_nil
      expect(subject.graded_by_id).to be_nil
    end

    it "persists the grade changes" do
      subject.clear_grade!

      expect(subject).to_not be_changed
    end
  end

  describe ".grade_modified" do
    it "returns all the grades that have been graded by someone" do
      modified = create :grade, graded_by_id: 123
      not_modified = create :grade, graded_by_id: nil

      expect(described_class.grade_modified).to eq [modified]
    end
  end

  describe "#grade_modified?" do
    it "returns true if it has been graded by someone" do
      subject.graded_by_id = 123

      expect(subject).to be_grade_modified
    end

    it "returns false if it has not been graded by someone" do
      subject.graded_by_id = nil

      expect(subject).to_not be_grade_modified
    end
  end

  describe "#raw_points" do
    it "converts raw_points from human readable strings" do
      subject.update(raw_points: "1,234")
      expect(subject.raw_points).to eq(1234)
    end

    it "is converts blank string to nil" do
      subject.update(raw_points: "")
      expect(subject.raw_points).to eq(nil)
    end
  end

  describe ".not_released" do
    it "returns all grades that are graded but require a release" do
      assignment = create :assignment, release_necessary: true
      not_released_grade = create :grade, assignment: assignment, status: "Graded"
      create :grade, assignment: assignment, status: "Released"
      create :grade, status: "Graded"

      expect(described_class.not_released).to eq [not_released_grade]
    end
  end

  describe ".released" do
    it "returns all the grades that are released" do
      released_grade = create :grade, status: "Released"
      create :grade, status: "In Progress"

      expect(described_class.released).to eq [released_grade]
    end
  end

  describe ".student_visible" do
    it "returns all grades that were released or were graded but no release was necessary" do
      graded_grade = create :grade, status: "Graded"
      released_grade = create :grade, status: "Released"
      assignment = create :assignment, release_necessary: true
      create :grade, assignment: assignment, status: "Graded"

      expect(described_class.student_visible).to include(released_grade, graded_grade)
    end
  end

  describe ".releasable_through" do
    it "returns assignment" do
      expect(described_class.releasable_relationship).to eq :assignment
    end
  end

  describe "calculation of final_points" do
    it "is nil when raw_points is nil" do
      subject.update(raw_points: nil)
      expect(subject.final_points).to eq(nil)
    end

    it "is the sum of raw_points and adjustment_points" do
      subject.update(raw_points: "1234", adjustment_points: -234)
      expect(subject.final_points).to eq(1000)
    end

    it "is 0 if the score is below the threshold" do
      subject.assignment.update(threshold_points: 1001)
      subject.update(raw_points: 1000)
      expect(subject.final_points).to eq(0)
    end
  end

  describe "calculating score" do
    it "is nil when raw_points is nil" do
      subject.update(raw_points: nil)
      expect(subject.score).to eq(nil)
    end

    it "is the same as final score when assignment isn't weighted" do
      subject.update(raw_points: "1234", adjustment_points: -234)
      expect(subject.score).to eq(1000)
    end

    it "is the final score weighted by the students weight for the assignment" do
      subject.assignment.assignment_type.update(student_weightable: true)
      create(:assignment_type_weight, student: subject.student, assignment_type: subject.assignment_type, weight: 3 )
      subject.update(raw_points: "1,234", adjustment_points: -234)
      expect(subject.score).to eq(3000)
    end
  end

  describe "when assignment is pass-fail" do
    before do
      subject.assignment.update(pass_fail: true)
    end

    it "saves the grades as zero" do
      subject.save!
      expect(subject.raw_points).to be 0
      expect(subject.predicted_score).to be <= 1
      expect(subject.final_points).to be 0
      expect(subject.full_points).to be 0
    end
  end

  describe "#feedback_read!" do
    it "marks the grade as read" do
      subject.feedback_read!
      expect(subject).to be_feedback_read
      elapsed = ((DateTime.now - subject.feedback_read_at.to_datetime) * 24 * 60 * 60).to_i
      expect(elapsed).to be < 5
    end
  end

  describe "#feedback_reviewed!" do
    it "marks the grade as reviewed" do
      subject.feedback_reviewed!
      expect(subject).to be_feedback_reviewed
      elapsed = ((DateTime.now - subject.feedback_reviewed_at.to_datetime) * 24 * 60 * 60).to_i
      expect(elapsed).to be < 5
    end
  end

  describe ".for_course" do
    it "returns all grades for a specific course" do
      course = create(:course)
      course_grade = create(:grade, course: course)
      another_grade = create(:grade)
      results = Grade.for_course(course)
      expect(results).to eq [course_grade]
    end
  end

  describe ".for_student" do
    it "returns all grades for a specific student" do
      student = create(:user)
      student_grade = create(:grade, student: student)
      another_grade = create(:grade)
      results = Grade.for_student(student)
      expect(results).to eq [student_grade]
    end
  end

  describe ".find_or_create" do
    it "finds and existing grade for assignment and student" do
      world = World.create.with(:course, :student, :assignment, :grade)
      results = Grade.find_or_create(world.assignment.id,world.student.id)
      expect(results).to eq world.grade
    end

    it "creates a grade for assignment and student if none exists" do
      world = World.create.with(:course, :student, :assignment)
      expect{Grade.find_or_create(world.assignment.id,world.student.id)}.to \
        change{ Grade.count }.by(1)
    end
  end

  describe ".find_or_create_grades" do
    let(:world) { World.create.with(:course, :assignment, :group) }
    let(:ids) { world.group.students.pluck(:id) }

    it "finds and existing grade for assignment and student" do
      results = Grade.find_or_create_grades(world.assignment.id, ids)
      expect(results.count).to eq ids.length
    end

    it "creates a grade for assignment and student if none exists" do
      expect { Grade.find_or_create_grades(world.assignment.id, ids) }.to \
        change{ Grade.count }.by(ids.length)
    end
  end
end
