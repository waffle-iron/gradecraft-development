require "./lib/showtime"

class Students::LeaderboardPresenter < Showtime::Presenter
  def course
    properties[:course]
  end

  def display_pseudonyms?
    course.in_team_leaderboard? || course.character_names?
  end

  def earned_badges
    @earned_badges ||=
      EarnedBadge.for_course(course)
        .where(student_id: student_ids)
        .order_by_created_at
        .includes(:badge)
  end

  def grade_scheme_elements
    @grade_scheme_elements ||=
      GradeSchemeElement.unscoped.for_course(course).order_by_low_range
  end

  def has_badges?
    course.has_badges?
  end

  def has_teams?
    course.has_teams?
  end

  def student_ids
    students.map(&:id)
  end

  def students
    @students ||= LeaderboardStudentCollection.new(User
      .unscoped_students_being_graded_for_course(course, team)
      .order_by_high_score, self)
  end

  def team_id
    properties[:team_id]
  end

  def team
    @team ||= teams.find_by(id: team_id) if team_id
  end

  def teams
    course.teams
  end

  def title
    "Leaderboard"
  end

  def team_memberships
    @team_memberships ||= TeamMembership.for_course(course)
      .where(student_id: student_ids)
      .includes(:team)
  end

  class LeaderboardStudentCollection
    include Enumerable

    attr_reader :presenter

    def initialize(students, presenter)
      @students = students
      @presenter = presenter
    end

    def each
      @students.each { |student| yield LeaderboardStudentDecorator.new(student, presenter) }
    end
  end

  class LeaderboardStudentDecorator < SimpleDelegator
    attr_reader :presenter

    def earned_badges
      presenter.earned_badges.select { |eb| eb.student_id == self.id }
    end

    def grade_scheme
      scheme = presenter.course.grade_scheme_elements.for_score(score)
      puts scheme.inspect
      scheme
    end

    def score
      self.cached_score_sql_alias
    end

    def team
      presenter.team_memberships.find { |tm| tm.student_id == self.id }.try(:team)
    end

    def initialize(student, presenter)
      @presenter = presenter
      super student
    end
  end
end
