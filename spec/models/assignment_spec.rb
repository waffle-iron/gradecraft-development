require "active_record_spec_helper"
require "toolkits/sanitization_toolkit"
require "toolkits/models/assignments_toolkit"

describe Assignment do
  include Toolkits::Models::AssignmentsToolkit

  subject { build(:assignment) }
  let(:assignment) { build :assignment }

  it_behaves_like "a model that needs sanitization", :description

  context "validations" do
    it "is valid with a name and assignment type" do
      expect(subject).to be_valid
    end

    it "is invalid without a name" do
      subject.name = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:name]).to include "can't be blank"
    end

    it "is invalid without an assignment type" do
      subject.assignment_type_id = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:assignment_type_id]).to include "can't be blank"
    end

    it "is invalid without a course" do
      subject.course_id = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:course_id]).to include "can't be blank"
    end

    it "is invalid if it is due before it is open" do
      subject.due_at = 2.days.from_now
      subject.open_at = 3.days.from_now
      expect(subject).to_not be_valid
      expect(subject.errors[:base]).to include "Due date must be after open date."
    end

    it "is invalid if accepting submissions before it is open" do
      subject.open_at = 2.days.from_now
      subject.accepts_submissions_until = 1.day.from_now
      expect(subject).to_not be_valid
      expect(subject.errors[:base]).to include "Submission accept date must be after open date."
    end

    it "is invalid accepting submissions before it is due" do
      subject.due_at = 2.days.from_now
      subject.accepts_submissions_until = 1.day.from_now
      expect(subject).to_not be_valid
      expect(subject.errors[:base]).to include "Submission accept date must be after due date."
    end
  end

  describe "#graded_or_released_scores" do
    before { subject.save }

    it "returns an array raw graded scores" do
      subject.grades.create student_id: create(:user).id, raw_score: 85, status: "Graded"
      expect(subject.graded_or_released_scores).to eq([85])
    end
  end

  describe "#assignment_files_attributes=" do
    it "supports multiple file uploads" do
      file_attribute_1 = fixture_file "test_file.txt", "txt"
      file_attribute_2 = fixture_file "test_image.jpg", "image/jpg"
      subject.assignment_files_attributes = { "0" => { "file" => [file_attribute_1, file_attribute_2] }}
      expect(subject.assignment_files.length).to eq 2
      expect(subject.assignment_files[0].filename).to eq "test_file.txt"
      expect(subject.assignment_files[1].filename).to eq "test_image.jpg"
    end
  end

  describe "#fetch_or_create_rubric" do
    it "returns a rubric if one exists" do
      rubric = create(:rubric, assignment: subject)
      expect(subject.fetch_or_create_rubric).to eq(rubric)
    end

    it "creates a rubric if one does not exist" do
      skip "pending"
      #expect(subject.fetch_or_create_rubric).to eq(Rubric.new)
    end
  end

  describe "#average" do
    before { subject.save }

    it "returns the average raw score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_score: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 5, status: "Graded"
      expect(subject.average).to eq 6
    end

    it "returns nil if there are no grades" do
      expect(subject.average).to be_nil
    end
  end

  describe "#earned_average" do
    before { subject.save }

    it "returns the average score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_score: 8, score: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 5, score: 8, status: "Graded"
      expect(subject.earned_average).to eq 6
    end

    it "returns 0 if there are no grades" do
      expect(subject.earned_average).to be_zero
    end
  end

  describe "#earned_score_count" do
    before { subject.save }

    it "returns only graded or released grades" do
      subject.grades.create student_id: create(:user).id
      expect(subject.earned_score_count).to be_empty
    end

    it "returns the number of unique scores for each grade" do
      subject.grades.create student_id: create(:user).id, raw_score: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 105, status: "Graded"
      expect(subject.earned_score_count).to eq({ 85 => 2, 105 => 1 })
    end
  end

  describe "#median" do
    before { subject.save }

    it "returns the median score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_score: 8, score: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 5, score: 8, status: "Graded"
      expect(subject.median).to eq 6
    end

    it "returns 0 if there are no grades" do
      expect(subject.median).to be_zero
    end
  end

  describe "#percentage_score_earned" do
    before { subject.save }

    it "returns the earned scores with a scores key" do
      subject.grades.create student_id: create(:user).id, raw_score: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 105, status: "Graded"
      scores = subject.percentage_score_earned[:scores]
      expect(scores).to include({ data: 1, name: 105 })
      expect(scores).to include({ data: 2, name: 85 })
    end
  end

  describe "pass-fail assignments" do
    it "sets point total to zero on save" do
      subject.point_total = 3000
      subject.pass_fail = true
      subject.save
      expect(subject.point_total).to eq(0)
    end
  end

  describe "#is_unlocked_for_student?" do
    let(:student) { create :user }

    it "is unlocked when there are no unlock conditions present" do
      expect(subject.is_unlocked_for_student?(student)).to eq true
    end

    it "is not unlocked when the unlock state for the student is not present" do
      subject.unlock_conditions.build
      expect(subject.is_unlocked_for_student?(student)).to eq false
    end

    it "is unlocked when the unlock state for the student is unlocked" do
      subject.unlock_states.build(student_id: student.id, unlocked: true)
      expect(subject.is_unlocked_for_student?(student)).to eq true
    end
  end

  describe "#check_unlock_status" do
    let(:student) { create :user }
    before { subject.save }

    it "returns a new unlock state if the goal of unlockables does not meet the number of unlocks" do
      subject.unlock_conditions.create! condition_id: subject.id,
        condition_type: subject.class, condition_state: "Blah"
      expect(subject.check_unlock_status(student)).to be_an_instance_of UnlockState
      expect(subject.unlock_states.last).to_not be_unlocked
    end

    context "when the number of conditions are met" do
      it "returns the updated unlock state when it is found" do
        condition = subject.unlock_conditions.create condition_id: subject.id,
          condition_type: subject.class, condition_state: "Blah"
        allow(condition).to receive(:is_complete?).with(student).and_return true
        state = subject.unlock_states.create(student_id: student.id,
                                             unlocked: false)
        expect(subject.check_unlock_status(student)).to eq state
        expect(state.reload).to be_unlocked
      end

      it "returns a new unlock state if it did not exist" do
        condition = subject.unlock_conditions.create condition_id: subject.id,
          condition_type: subject.class, condition_state: "Blah"
        allow(condition).to receive(:is_complete?).with(student).and_return true
        expect(subject.check_unlock_status(student)).to eq \
          subject.unlock_states.last
        expect(subject.unlock_states.last.unlockable_type).to eq subject.class.name
        expect(subject.unlock_states.last.student).to eq student
        expect(subject.unlock_states.last).to be_unlocked
        expect(subject.unlock_states.last.unlockable_id).to eq subject.id
      end
    end
  end

  describe "#visible_for_student?(student)" do
    it "returns true if the assignment is visible" do
      assignment = create(:assignment)
      student = create(:user)
      expect(assignment.visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment is invisible" do
      assignment = create(:assignment, visible: false)
      student = create(:user)
      expect(assignment.visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment is invisible but the student has earned a grade" do
      assignment = create(:assignment)
      student = create(:user)
      grade = create(:grade, student: student, assignment: assignment)
      expect(assignment.visible_for_student?(student)).to eq(true)
    end

    it "returns true if the assignment is locked but visible" do
      assignment= create(:assignment, visible_when_locked: true)
      student = create(:user)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment)
      expect(assignment.visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment is invisible when locked and the student has not met the conditions" do
      assignment = create(:assignment, visible_when_locked: false)
      student = create(:user)
      badge = create(:badge)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment.id, unlockable_type: "Assignment", condition_id: badge.id, condition_state: "Earned")
      expect(assignment.visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment is invisible when locked and the student has met the conditions" do
      assignment = create(:assignment, visible_when_locked: false)
      student = create(:user)
      assignment_2 = create(:assignment)
      submission = create(:submission, assignment: assignment_2, student: student)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment, condition_id: assignment_2.id, condition_type: "Assignment", condition_state: "Submitted")
      expect(assignment.visible_for_student?(student)).to eq(true)
    end
  end

  describe "#description_visible_for_student?(student)" do
    it "returns true if the assignment is visible" do
      assignment = create(:assignment)
      student = create(:user)
      expect(assignment.description_visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment is invisible" do
      assignment = create(:assignment, visible: false)
      student = create(:user)
      expect(assignment.description_visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment description is invisible but the student has earned a grade" do
      assignment = create(:assignment, show_description_when_locked: false )
      student = create(:user)
      grade = create(:grade, student: student, assignment: assignment)
      expect(assignment.description_visible_for_student?(student)).to eq(true)
    end

    it "returns true if the assignment is locked but the description is visible" do
      assignment= create(:assignment, visible_when_locked: true,  show_description_when_locked: true )
      student = create(:user)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment)
      expect(assignment.description_visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment description is invisible when locked and the student has not met the conditions" do
      assignment = create(:assignment, visible_when_locked: true, show_description_when_locked: false )
      student = create(:user)
      badge = create(:badge)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment.id, unlockable_type: "Assignment", condition_id: badge.id, condition_state: "Earned")
      expect(assignment.description_visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment description is invisible when locked and the student has met the conditions" do
      assignment = create(:assignment, visible_when_locked: true, show_description_when_locked: false )
      student = create(:user)
      assignment_2 = create(:assignment)
      submission = create(:submission, assignment: assignment_2, student: student)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment, condition_id: assignment_2.id, condition_type: "Assignment", condition_state: "Submitted")
      expect(assignment.description_visible_for_student?(student)).to eq(true)
    end
  end

  describe "#points_visible_for_student?(student)" do
    it "returns true if the assignment is visible" do
      assignment = create(:assignment)
      student = create(:user)
      expect(assignment.points_visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment is invisible" do
      assignment = create(:assignment, visible: false)
      student = create(:user)
      expect(assignment.points_visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment points is invisible but the student has earned a grade" do
      assignment = create(:assignment, show_points_when_locked: false )
      student = create(:user)
      grade = create(:grade, student: student, assignment: assignment)
      expect(assignment.points_visible_for_student?(student)).to eq(true)
    end

    it "returns true if the assignment is locked but the points are visible" do
      assignment= create(:assignment, visible_when_locked: true,  show_points_when_locked: true )
      student = create(:user)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment)
      expect(assignment.points_visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment points are invisible when locked and the student has not met the conditions" do
      assignment = create(:assignment, visible_when_locked: true, show_points_when_locked: false )
      student = create(:user)
      badge = create(:badge)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment.id, unlockable_type: "Assignment", condition_id: badge.id, condition_state: "Earned")
      expect(assignment.points_visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment points are invisible when locked and the student has met the conditions" do
      assignment = create(:assignment, visible_when_locked: true, show_points_when_locked: false )
      student = create(:user)
      assignment_2 = create(:assignment)
      submission = create(:submission, assignment: assignment_2, student: student)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment, condition_id: assignment_2.id, condition_type: "Assignment", condition_state: "Submitted")
      expect(assignment.points_visible_for_student?(student)).to eq(true)
    end
  end

  describe "#name_visible_for_student?(student)" do
    it "returns true if the assignment is visible" do
      assignment = create(:assignment)
      student = create(:user)
      expect(assignment.name_visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment is invisible" do
      assignment = create(:assignment, visible: false)
      student = create(:user)
      expect(assignment.name_visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment name is invisible but the student has earned a grade" do
      assignment = create(:assignment, show_points_when_locked: false )
      student = create(:user)
      grade = create(:grade, student: student, assignment: assignment)
      expect(assignment.name_visible_for_student?(student)).to eq(true)
    end

    it "returns true if the assignment is locked but the name is visible" do
      assignment= create(:assignment, visible_when_locked: true,  show_name_when_locked: true )
      student = create(:user)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment)
      expect(assignment.name_visible_for_student?(student)).to eq(true)
    end

    it "returns false if the assignment name is invisible when locked and the student has not met the conditions" do
      assignment = create(:assignment, visible_when_locked: true, show_name_when_locked: false )
      student = create(:user)
      badge = create(:badge)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment.id, unlockable_type: "Assignment", condition_id: badge.id, condition_state: "Earned")
      expect(assignment.name_visible_for_student?(student)).to eq(false)
    end

    it "returns true if the assignment name is invisible when locked and the student has met the conditions" do
      assignment = create(:assignment, visible_when_locked: true, show_name_when_locked: false )
      student = create(:user)
      assignment_2 = create(:assignment)
      submission = create(:submission, assignment: assignment_2, student: student)
      unlock_condition = create(:unlock_condition, unlockable_id: assignment, condition_id: assignment_2.id, condition_type: "Assignment", condition_state: "Submitted")
      expect(assignment.name_visible_for_student?(student)).to eq(true)
    end
  end

  describe "#unlock_condition_count_met_for" do
    let(:student) { create :user }
    before { subject.save }

    it "returns zero if there are no unlock conditions" do
      expect(subject.unlock_condition_count_met_for(student)).to be_zero
    end

    it "returns zero if none of the conditions were met for the student" do
      condition = subject.unlock_conditions.create condition_id: subject.id,
          condition_type: subject.class, condition_state: "Blah"
      expect(subject.unlock_condition_count_met_for(student)).to be_zero
    end

    it "returns the number of conditions that were complete for the student" do
      met_condition = subject.unlock_conditions.create condition_id: subject.id,
          condition_type: subject.class, condition_state: "Blah"
      allow(met_condition).to receive(:is_complete?).with(student).and_return true
      condition = subject.unlock_conditions.create condition_id: subject.id,
          condition_type: subject.class, condition_state: "Blah"
      expect(subject.unlock_condition_count_met_for(student)).to eq 1
    end
  end

  describe "#completion_rate" do
    let(:course) { double(:course, graded_student_count: 10) }
    before { allow(subject).to receive(:grade_count).and_return 8 }

    it "calculates the number of grades divided by the number of students in the course" do
      expect(subject.completion_rate(course)).to eq 80
    end

    it "handles if there are no graded students" do
      allow(course).to receive(:graded_student_count).and_return 0
      expect(subject.completion_rate(course)).to be_zero
    end
  end

  describe "#copy" do
    let(:assignment) { build :assignment }
    subject { assignment.copy }

    it "prepends the name with 'Copy of'" do
      assignment.name = "Table of elements"
      expect(subject.name).to eq "Copy of Table of elements"
    end

    it "makes a shallow copy of the fields" do
      assignment.description = "This is a great assignment"
      expect(subject.description).to eq "This is a great assignment"
    end

    it "saves the copy if the assignment is saved" do
      assignment.save
      expect(subject).to_not be_new_record
    end

    it "copies the assignment score levels" do
      assignment.save
      assignment.assignment_score_levels.create
      expect(subject.assignment_score_levels.size).to eq 1
      expect(subject.assignment_score_levels.map(&:assignment_id)).to eq [subject.id]
    end

    it "copies the rubric" do
      assignment.save
      assignment.build_rubric
      expect(subject.rubric.assignment_id).to eq subject.id
      expect(subject.rubric).to_not be_new_record
    end

    it "copies the assignment files", focus: true do
      assignment.save
      assignment.assignment_files.create file: fixture_file("test_file.txt", "txt")

      expect(subject.assignment_files.count).to eq 1
    end
  end

  describe "#future?" do
    it "is not for the future if there is no due date" do
      subject.due_at = nil
      expect(subject).to_not be_future
    end

    it "is not for the future if the due date is in the past" do
      subject.due_at = 2.days.ago
      expect(subject).to_not be_future
    end

    it "is for the future if the due date is in the future" do
      subject.due_at = 2.days.from_now
      expect(subject).to be_future
    end
  end

  describe "#grade_checkboxes?" do
    it "should render checkboxes if the mass grade type is checkbox" do
      subject.mass_grade_type = "Checkbox"
      expect(subject).to be_grade_checkboxes
    end
  end

  describe "#predictor_display_type" do
    it "is set to checkbox for 'Fixed' display type" do
      subject.points_predictor_display = "Fixed"
      subject.pass_fail = false
      expect(subject.predictor_display_type).to eq "checkbox"
    end

    it "is set to checkbox for pass fail assignments" do
      subject.points_predictor_display = "Fixed"
      subject.pass_fail = true
      expect(subject.predictor_display_type).to eq "checkbox"
    end

    it "is set to slider for 'Slider' display type" do
      subject.points_predictor_display = "Slider"
      expect(subject.predictor_display_type).to eq "slider"
    end

    it "is set to slider by default" do
      subject.points_predictor_display = nil
      expect(subject.predictor_display_type).to eq "slider"
    end
  end

  describe "#grade_count" do
    before { subject.save }

    it "counts the number of grades that were graded or released" do
      subject.grades.create student_id: create(:user).id, raw_score: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 85, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 105
      expect(subject.grade_count).to eq 2
    end
  end

  describe "#grade_for_student" do
    let(:student) { create :user }
    before { subject.save }

    it "returns the first visible grade for the student" do
      grade = subject.grades.create student_id: student.id, raw_score: 85, status: "Graded"
      expect(subject.grade_for_student(student)).to eq grade
    end
  end

  describe "#grade_level" do
    it "returns the assignment score level for the grade's score" do
      grade = build(:grade, raw_score: 123)
      subject.assignment_score_levels.build name: "First level", value: 123
      expect(subject.grade_level(grade)).to eq "First level"
    end

    it "returns nil if there is no assignment score level found" do
      grade = build(:grade, raw_score: 123)
      subject.assignment_score_levels.build name: "First level", value: 456
      expect(subject.grade_level(grade)).to be_nil
    end
  end

  describe "#grade_radio?" do
    it "should render a radio list if the mass grade type is radio and there are assignment score levels" do
      subject.mass_grade_type = "Radio Buttons"
      subject.assignment_score_levels.build
      expect(subject).to be_grade_radio
    end

    it "should not render a radio list if there are no assignment score levels" do
      subject.mass_grade_type = "Radio List"
      expect(subject).to_not be_grade_radio
    end
  end

  describe "#grade_select?" do
    it "should render a select if the mass grade type is select and there are assignment score levels" do
      subject.mass_grade_type = "Select List"
      subject.assignment_score_levels.build
      expect(subject).to be_grade_select
    end

    it "should not render a select if there are no assignment score levels" do
      subject.mass_grade_type = "Select List"
      expect(subject).to_not be_grade_select
    end
  end

  describe "#grade_text?" do
    it "should render a text box if the mass grade type is text" do
      subject.mass_grade_type = "Text"
      expect(subject).to be_grade_text
    end
  end

  describe "#has_levels?" do
    it "has levels if there are assignment score levels" do
      subject.assignment_score_levels.build
      expect(subject).to have_levels
    end
  end

  describe "#has_rubric?" do
    it "has a rubric if one is defined" do
      subject.build_rubric
      expect(subject).to have_rubric
    end
  end

  describe "#high_score" do
    before { subject.save }

    it "returns the maximum raw score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_score: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 5, status: "Graded"
      expect(subject.high_score).to eq 8
    end
  end

  describe "#is_predicted_by_student?" do
    let(:student) { create :user }
    before { subject.save }

    it "returns true if the first grade for the student has a predicted score" do
      subject.grades.create student_id: student.id, raw_score: 85, status: "Graded", predicted_score: 83
      expect(subject.is_predicted_by_student?(student)).to eq true
    end

    it "returns false if there are no grades for the student" do
      expect(subject.is_predicted_by_student?(student)).to eq false
    end
  end

  describe "#low_score" do
    before { subject.save }

    it "returns the minimum raw score for a graded grade" do
      subject.grades.create student_id: create(:user).id, raw_score: 8, status: "Graded"
      subject.grades.create student_id: create(:user).id, raw_score: 5, status: "Graded"
      expect(subject.low_score).to eq 5
    end
  end

  describe "#predicted_count" do
    it "returns the number of grades that are predicted to have a score greater than zero" do
      grades = double(:grades, predicted_to_be_done: 43.times.to_a)
      allow(subject).to receive(:grades).and_return grades
      expect(subject.predicted_count).to eq 43
    end
  end

  describe "#soon?" do
    it "is not soon if there is no due date" do
      subject.due_at = nil
      expect(subject).to_not be_soon
    end

    it "is not soon if the due date is too far in the future" do
      subject.due_at = 8.days.from_now
      expect(subject).to_not be_soon
    end

    it "is soon if the due date is within 7 days from now" do
      subject.due_at = 2.days.from_now
      expect(subject).to be_soon
    end
  end

  describe "#submission_rate" do
    let(:course) { double(:course, graded_student_count: 10) }
    let(:submissions) { double(:submissions, count: 4) }
    before { allow(subject).to receive(:submissions).and_return submissions }

    it "calculates the number of submissions divided by the number of students in the course" do
      expect(subject.submission_rate(course)).to eq 40
    end

    it "handles if there are no graded students" do
      allow(course).to receive(:graded_student_count).and_return 0
      expect(subject.submission_rate(course)).to be_zero
    end
  end

  describe "#opened?" do
    it "is opened if there is no open at date set" do
      subject.open_at = nil
      expect(subject).to be_opened
    end

    it "is opened if the open at date is in the past" do
      subject.open_at = 2.days.ago
      expect(subject).to be_opened
    end

    it "is not opened if the assignment opens in the future" do
      subject.open_at = 2.days.from_now
      expect(subject).to_not be_opened
    end
  end

  describe "#overdue" do
    it "is not overdue if there is no due date" do
      subject.due_at = nil
      expect(subject).to_not be_overdue
    end

    it "is not overdue if the due date is in the future" do
      subject.due_at = 2.days.from_now
      expect(subject).to_not be_overdue
    end

    it "is overdue if the due date has past" do
      subject.due_at = 2.days.ago
      expect(subject).to be_overdue
    end
  end

  describe "#accepting_submissions?" do
    it "is accepting submissions if no acceptance date was set" do
      subject.accepts_submissions_until = nil
      expect(subject).to be_accepting_submissions
    end

    it "is accepting submissions if the acceptance date is in the future" do
      subject.accepts_submissions_until = 2.days.from_now
      expect(subject).to be_accepting_submissions
    end

    it "is not accepting submissions if the acceptance date was in the past" do
      subject.accepts_submissions_until = 2.days.ago
      expect(subject).to_not be_accepting_submissions
    end
  end

  describe "#submissions_have_closed?" do
    it "is true if the assignment no longer accepts submissions" do
      subject.accepts_submissions_until = 2.days.ago
      expect(subject.submissions_have_closed?).to be_truthy
    end

    it "is false if assignment accepts submisions currently or in the future" do
      subject.accepts_submissions_until = nil
      expect(subject.submissions_have_closed?).to_not be_truthy
    end

    it "is false if assignment never accepts submissions" do
      subject.accepts_submissions_until = 2.days.from_now
      expect(subject.submissions_have_closed?).to_not be_truthy
    end
  end

  describe "#open?" do
    before do
      subject.open_at = 4.days.ago
      subject.due_at = 2.days.ago
      subject.accepts_submissions_until = 2.days.ago
    end

    it "is open if there is no open date and there is no due date" do
      subject.open_at = nil
      subject.due_at = nil
      expect(subject).to be_open
    end

    it "is open if the open date has passed but there is no due date" do
      subject.due_at = nil
      expect(subject).to be_open
    end

    it "is open if there is no open date but there is a future due date" do
      subject.open_at = nil
      subject.due_at = 2.days.from_now
      expect(subject).to be_open
    end

    it "is open if there is no open date, the due date has passed and it does not have an accept date" do
      subject.open_at = nil
      subject.accepts_submissions_until = nil
      expect(subject).to be_open
    end

    it "is open if there is no open date, the due date has passed and it has a future accept date" do
      subject.open_at = nil
      subject.accepts_submissions_until = 2.days.from_now
      expect(subject).to be_open
    end

    it "is open if there is a previous open date, a future due date and it does not have an accept date" do
      subject.open_at = nil
      subject.due_at = 2.days.from_now
      subject.accepts_submissions_until = nil
      expect(subject).to be_open
    end

    it "is open if there is a previous open date, a previous due date and it does not have an accept date" do
      subject.accepts_submissions_until = nil
      expect(subject).to be_open
    end

    it "is open if there is a previous open date and a future accept date" do
      subject.accepts_submissions_until = 2.days.from_now
      expect(subject).to be_open
    end
  end

  describe "#to_json" do
    it "returns a json representation" do
      json = subject.to_json
      expect(json).to eq({ id: subject.id }.to_json)
    end
  end
end
