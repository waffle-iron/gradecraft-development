require "active_record_spec_helper"
require "./app/presenters/students/leaderboard_presenter"

describe Students::LeaderboardPresenter do
  let(:course) { create(:course) }
  subject { described_class.new course: course }

  describe "#display_pseudonyms?" do
    it "is displayed if the course is shown in the leaderboard or it has character names" do
      allow(course).to \
        receive_messages(in_team_leaderboard?: true, character_names?: false)
      expect(subject).to be_display_pseudonyms
    end
  end

  describe "#initialize" do
    it "initializes with a course" do
      expect(described_class.new(course: course).course).to eq course
    end
  end

  describe "#earned_badges" do
    let(:student1) { create :student_course_membership, course: course }
    let(:student2) { create :student_course_membership, course: course }
    let!(:earned_badge1) { create :earned_badge, course: course, student: student1.user }
    let!(:earned_badge2) { create :earned_badge, course: course, student: student2.user }

    it "returns the earned badges for all the students" do
      expect(subject.earned_badges).to eq [earned_badge1, earned_badge2]
    end
  end

  describe "#grade_scheme_elements" do
    let!(:high_grade_scheme_element) { create :grade_scheme_element_high, course: course }
    let!(:low_grade_scheme_element) { create :grade_scheme_element_low, course: course }

    it "returns all the grade scheme elements for the course" do
      expect(subject.grade_scheme_elements).to eq [low_grade_scheme_element, high_grade_scheme_element]
    end
  end

  describe "has_badges?" do
    it "returns true if the course has badges" do
      allow(course).to receive(:has_badges?).and_return true
      expect(subject).to be_has_badges
    end
  end

  describe "#has_teams?" do
    it "returns true if the course has teams" do
      allow(course).to receive(:has_teams?).and_return true
      expect(subject).to be_has_teams
    end
  end

  describe "#students" do
    let!(:student1) { create :student_course_membership, course: course }
    let!(:student2) { create :student_course_membership, course: course }
    let(:team) { create :team, course: course }

    it "returns a list of users that are being graded" do
      expect(subject.students.map(&:id)).to eq [student1, student2].map(&:user_id)
    end

    it "returns a list of users on the team that are being graded" do
      create :team_membership, student: student1.user, team: team
      allow(subject).to receive(:team_id).and_return team.id
      allow(subject).to receive(:team).and_return team
      expect(subject.students.map(&:id)).to eq [student1.user_id]
    end
  end

  describe "#student_ids" do
    let!(:student1) { create :student_course_membership, course: course }
    let!(:student2) { create :student_course_membership, course: course }

    it "returns the user ids for the students" do
      expect(subject.student_ids).to eq [student1, student2].map(&:user_id)
    end
  end

  describe "#team" do
    subject { described_class.new course: course, team_id: 123 }

    it "returns the team based on the team_id parameter" do
      team = double(:team, id: 123)
      teams = double(:relation, find_by: team)
      allow(course).to receive(:teams).and_return teams
      expect(subject.team).to eq team
    end
  end

  describe "#teams" do
    it "returns the teams on the course" do
      team = double(:team)
      allow(course).to receive(:teams).and_return [team]
      expect(subject.teams).to eq [team]
    end
  end

  describe "#team_memberships" do
    let!(:student1) { create :student_course_membership, course: course }
    let!(:student2) { create :student_course_membership, course: course }
    let(:team) { create :team, course: course }

    it "returns the team memberships for all the students" do
      membership = create :team_membership, student: student1.user, team: team
      expect(subject.team_memberships).to eq [membership]
    end
  end

  describe "#title" do
    it "always returns 'Leaderboard'" do
      expect(subject.title).to eq "Leaderboard"
    end
  end
end
