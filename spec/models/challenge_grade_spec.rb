require "active_record_spec_helper"

describe ChallengeGrade do
  subject { build(:challenge_grade) }

  context "validations" do
    it "is valid with a team, and a challenge" do
      expect(subject).to be_valid
    end

    it "is invalid without a team" do
      subject.team = nil
      expect(subject).to be_invalid
    end

    it "is invalid without a challenge" do
      subject.challenge = nil
      expect(subject).to be_invalid
    end
  end

  describe "#recalculate_student_and_team_scores" do
    # team.update_revised_team_score
    # if team.course.add_team_score_to_student?
    #   team.recalculate_student_scores
    # end
  end

  describe ".releasable_through" do
    it "returns challenge" do
      expect(described_class.releasable_relationship).to eq :challenge
    end
  end

  describe "#score" do
    it "returns the challenge grade score if present" do
      challenge_grade = create(:challenge_grade, score: 100)
      expect(challenge_grade.score).to eq(100)
    end

    it "returns nil if there's no score present" do
      challenge_grade = create(:challenge_grade, score: nil)
      expect(challenge_grade.score).to eq(nil)
    end
  end

  describe ".student_visible" do
    it "returns all grades that were released or were graded but no release was necessary" do
      graded_grade = create :challenge_grade, status: "Graded"
      released_grade = create :challenge_grade, status: "Released"
      create :grades_not_released_challenge_grade

      expect(described_class.student_visible).to eq [graded_grade, released_grade]
    end
  end

  describe "#cache_team_score" do
    it "triggers the resave of a team" do
      team = create(:team, score: 0)
      challenge_grade = create(:challenge_grade, team: team, score: 100, status: "Released")
      challenge_grade.cache_team_score
      expect(team.score).to eq(100)
    end
  end

  describe "#is_graded?" do
    it "returns true if the challenge grade is graded" do
      challenge_grade = create(:challenge_grade, status: "Graded")
      expect(challenge_grade.is_graded?).to eq(true)
    end
    it "returns false if the challenge grade is not graded" do
      challenge_grade = create(:challenge_grade, status: nil)
      expect(challenge_grade.is_graded?).to eq(false)
    end
  end

  describe "#is_released?" do
    it "returns true if the challenge grade is released" do
      challenge_grade = create(:challenge_grade, status: "Released")
      expect(challenge_grade.is_released?).to eq(true)
    end

    it "returns false if the challenge grade is not graded" do
      challenge_grade = create(:challenge_grade, status: nil)
      expect(challenge_grade.is_released?).to eq(false)
    end

    it "returns false if the challenge grade is graded but not released" do
      challenge_grade = create(:challenge_grade, status: "Graded")
      expect(challenge_grade.is_released?).to eq(false)
    end
  end

  describe "#is_student_visible?" do
    it "returns true if the challenge requires release and the grade has been released" do
      challenge_grade = create(:challenge_grade, status: "Released")
      expect(challenge_grade.is_student_visible?).to eq(true)
    end

    it "returns false if the challenge requires release and the grade has not been released" do
      challenge = create(:challenge, release_necessary: true)
      challenge_grade = create(:challenge_grade, challenge: challenge, status: "Graded")
      expect(challenge_grade.is_student_visible?).to eq(false)
    end

    it "returns true if the challenge does not require release and the grade is graded" do
      challenge_grade = create(:challenge_grade, status: "Graded")
      expect(challenge_grade.is_student_visible?).to eq(true)
    end

    it "returns false if the challenge does not require release and the grade has not been graded" do
      challenge_grade = create(:challenge_grade, status: nil)
      expect(challenge_grade.is_student_visible?).to eq(false)
    end
  end
end
