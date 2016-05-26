require "spec_helper"
require "./app/presenters/badges/show_presenter"

describe Badges::ShowPresenter do
  let(:badge) do
    double(:badge,
      name: "Badgerino",
      earned_badges: "all earned badges")
  end

  let(:course) do
    double(:course,
      students_being_graded_by_team: "team students being graded",
      students_being_graded: "all students being graded")
  end

  let(:student) do
    double(:student,
      visible_earned_badges_for_badge: "my earned badges")
  end

  let(:teams) { double(:teams, find_by: "Team A") }
  let(:params) {{ team_id: 123 }}

  subject do
    Badges::ShowPresenter.new(
      { badge: badge,
        course: course,
        student: student,
        teams: teams,
        params: params
      }
    )
  end

  describe "#course" do
    it "is the course that is passed in as a property" do
      expect(subject.course).to eq course
    end
  end

  describe "#badge" do
    it "is the badge that is passed in as a property" do
      expect(subject.badge).to eq badge
    end
  end

  describe "#student" do
    it "is the student that is passed in as a property" do
      expect(subject.student).to eq student
    end
  end

  describe "#title" do
    it "is the badge name" do
      expect(subject.title).to eq badge.name
    end
  end

  describe "#teams" do
    it "is the teams that is passed in as a property" do
      expect(subject.teams).to eq teams
    end
  end

  describe "#params" do
    it "is the params that is passed in as a property" do
      expect(subject.params).to eq params
    end
  end

  describe "#team" do
    it "returns the team from teams when team_id is present" do
      expect(subject.team).to eq "Team A"
    end

    it "returns nil if team_id is nil" do
      subject = Badges::ShowPresenter.new({ teams: teams, params: {} })
      expect(subject.team).to eq nil
    end
  end

  describe "#students" do
    it "returns students in team being graded if params has team" do
      expect(subject.students).to eq "team students being graded"
    end

    it "returns all students being graded if no team in params" do
      subject = Badges::ShowPresenter.new(
        { course: course, teams: teams, params: {} }
      )
      expect(subject.students).to eq "all students being graded"
    end
  end

  describe "#earned_badges" do
    it "returns students earned badges if student present" do
      expect(subject.earned_badges).to eq("my earned badges")
    end

    it "returns all earned badges for badge when student is absent" do
      subject = Badges::ShowPresenter.new(badge: badge)
      expect(subject.earned_badges).to eq("all earned badges")
    end
  end

  describe "#view_student_context?" do
    it "is true when the student is in the context" do
      expect(subject.view_student_context?).to be_truthy
    end

    it "is false when there is no student in context" do
      subject = Badges::ShowPresenter.new()
      expect(subject.view_student_context?).to be_falsey
    end
  end
end
