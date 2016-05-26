require "./app/models/null_grade"
require "./app/models/null_student"
require "./lib/grade_proctor"

describe NullGrade do
  subject { NullGrade.new }

  it "has a nil score" do
    expect(subject.score).to be_nil
  end

  it "has a nil raw score" do
    expect(subject.raw_score).to be_nil
  end

  it "has a nil final score" do
    expect(subject.final_score).to eq(nil)
  end

  it "has a nil final points" do
    expect(subject.final_points).to eq(nil)
  end

  it "has nil feedback" do
    expect(subject.feedback).to be_nil
  end

  it "has a nil pass/fail status" do
    expect(subject.pass_fail_status).to eq(nil)
  end

  it "has a nil status" do
    expect(subject.status).to eq(nil)
  end

  it "has a nil updated at timestamp" do
    expect(subject.updated_at).to eq(nil)
  end

  it "has a nil graded at timestamp" do
    expect(subject.graded_at).to eq(nil)
  end

  it "has a team id of zero" do
    expect(subject.team_id).to eq(0)
  end

  it "has a course id of zero" do
    expect(subject.course_id).to eq(0)
  end

  it "has a student id of zero" do
    expect(subject.student_id).to eq(0)
  end

  it "is student visible" do
    expect(subject).to be_is_student_visible
  end

  it "is not released" do
    expect(subject).to_not be_is_released
  end

  it "is not excluded" do
    expect(subject).to_not be_excluded_from_course_score
  end

  it "is graded" do
    expect(subject).to be_is_graded
  end

  it "has a zero id" do
    expect(subject.id).to eq(0)
  end

  it "returns 555 for the point total" do
    expect(subject.point_total).to eq(555)
  end

  it "handles queries for assignments with closed submissions" do
    expect(subject.assignment.submissions_have_closed?).to be_falsey
  end

  it "handles queries for assignments accepting submissions" do
    expect(subject.assignment.accepts_submissions?).to be_falsey
  end

  it "returns a null student for student" do
    expect(subject.student.class).to eq(NullStudent)
  end

  it "returns a null course for course" do
    expect(subject.course.class).to eq(NullCourse)
  end

  it "is viewable with a GradeProctor" do
    expect(GradeProctor.new(subject)).to be_viewable
  end
end
