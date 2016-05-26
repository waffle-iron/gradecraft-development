require_relative "role"

class Course < ActiveRecord::Base
  include Copyable
  include UploadsMedia

  after_create :create_admin_memberships

  # Note: we are setting the role scopes as instance methods,
  # not class methods, so that they are limited to the users
  # of the current course
  Role.all.each do |role|
    define_method(role.pluralize) do
      User.with_role_in_course(role, self)
    end
  end

  # Staff returns all professors and GSI for the course.
  # Note that this is different from is_staff? which currently
  # includes Admin users
  def staff
    User.with_role_in_course("staff", self)
  end

  def instructors_of_record
    InstructorsOfRecord.for(self).users
  end

  def instructors_of_record_ids
    instructors_of_record.map(&:id)
  end

  def instructors_of_record_ids=(value)
    user_ids = value.map(&:to_i)
    InstructorsOfRecord.for(self).update_course_memberships(user_ids)
  end

  def students_being_graded
    User.students_being_graded(self)
  end

  def students_being_graded_by_team(team)
    User.students_being_graded(self,team)
  end

  def students_by_team(team)
    User.students_by_team(self, team)
  end

  attr_accessible :courseno, :name,
    :semester, :year, :badge_setting, :team_setting, :instructors_of_record_ids,
    :team_term, :user_term, :section_leader_term, :group_term, :lti_uid,
    :user_id, :course_id, :homepage_message, :group_setting, :syllabus,
    :character_names, :team_roles, :character_profiles, :hide_analytics,
    :total_assignment_weight, :assignment_weight_close_at,
    :assignment_weight_type, :has_submissions, :teams_visible,
    :weight_term, :max_group_size, :min_group_size, :fail_term, :pass_term,
    :max_assignment_weight, :assignments, :default_assignment_weight,
    :accepts_submissions, :tagline, :academic_history_visible, :office, :phone,
    :class_email, :twitter_handle, :twitter_hashtag, :location, :office_hours,
    :meeting_times, :use_timeline, :show_see_details_link_in_timeline,
    :assignment_term, :challenge_term, :badge_term, :grading_philosophy,
    :team_score_average, :team_challenges, :team_leader_term,
    :max_assignment_types_weighted, :point_total, :in_team_leaderboard,
    :grade_scheme_elements_attributes, :add_team_score_to_student, :status,
    :assignments_attributes, :start_date, :end_date

  with_options dependent: :destroy do |c|
    c.has_many :student_academic_histories
    c.has_many :assignment_types
    c.has_many :assignments
    c.has_many :announcements
    c.has_many :badges
    c.has_many :challenges
    c.has_many :challenge_grades, through: :challenges
    c.has_many :earned_badges
    c.has_many :grade_scheme_elements, -> { extending GradeSchemeElementScoringExtension }
    c.has_many :grades
    c.has_many :groups
    c.has_many :group_memberships
    c.has_many :submissions
    c.has_many :teams
    c.has_many :course_memberships
    c.has_many :submissions_exports
    c.has_many :events
  end

  has_many :users, through: :course_memberships
  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :assignments

  mount_uploader :syllabus, CourseSyllabusUploader

  accepts_nested_attributes_for :grade_scheme_elements, allow_destroy: true

  validates_presence_of :name, :courseno
  validates_numericality_of :max_group_size, allow_nil: true, greater_than_or_equal_to: 1
  validates_numericality_of :min_group_size, allow_nil: true, greater_than_or_equal_to: 1

  validates_numericality_of :total_assignment_weight, allow_blank: true
  validates_numericality_of :max_assignment_weight, allow_blank: true
  validates_numericality_of :max_assignment_types_weighted, allow_blank: true
  validates_numericality_of :default_assignment_weight, allow_blank: true
  validates_numericality_of :point_total, allow_blank: true

  validates_format_of :twitter_hashtag, with: /\A[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*\z/, allow_blank: true, length: { within: 3..20 }

  validate :max_more_than_min

  scope :alphabetical, -> { order("courseno ASC") }
  scope :active, -> { where(status: true) }
  scope :inactive, -> { where.not(status: true) }

  def self.find_or_create_by_lti_auth_hash(auth_hash)
    criteria = { lti_uid: auth_hash["extra"]["raw_info"]["context_id"] }
    where(criteria).first || create!(criteria) do |c|
      c.lti_uid = auth_hash["extra"]["raw_info"]["context_id"]
      c.courseno = auth_hash["extra"]["raw_info"]["context_label"]
      c.name = auth_hash["extra"]["raw_info"]["context_title"]
      c.year = Date.today.year
    end
  end

  def assignment_term
    super.presence || "Assignment"
  end

  def badge_term
    super.presence || "Badge"
  end

  def challenge_term
    super.presence || "Challenge"
  end

  def fail_term
    super.presence || "Fail"
  end

  def group_term
    super.presence || "Group"
  end

  def pass_term
    super.presence || "Pass"
  end

  def team_term
    super.presence || "Team"
  end

  def team_leader_term
    super.presence || "Team Leader"
  end

  def weight_term
    super.presence || "Multiplier"
  end

  def user_term
    super.presence || "Player"
  end

  def copy(attributes={})
    ModelCopier.new(self).copy(attributes: attributes,
                               associations: [
                                 :badges,
                                 { assignment_types: { course_id: :id }},
                                 :challenges,
                                 :grade_scheme_elements
                               ],
                               options: { prepend: { name: "Copy of " }})
  end

  def has_teams?
    team_setting == true
  end

  def has_team_challenges?
    team_challenges == true
  end

  def teams_visible?
    teams_visible == true
  end

  def in_team_leaderboard?
    in_team_leaderboard == true
  end

  def has_badges?
    badge_setting == true
  end

  def valuable_badges?
    badges.any? { |badge| badge.point_total.present? && badge.point_total > 0 }
  end

  def has_groups?
    group_setting == true
  end

  def min_group_size
    super.presence || 2
  end

  def max_group_size
    super.presence || 6
  end

  def formatted_tagline
    if tagline.present?
      tagline
    else
      " "
    end
  end

  def formatted_short_name
    if semester.present? && year.present?
      "#{self.courseno} #{(self.semester).capitalize.first[0]}#{self.year}"
    else
      "#{courseno}"
    end
  end

  # total number of points 'available' in the course - sometimes set by an
  # instructor as a cap, sometimes just the sum of all assignments
  def total_points
    point_total || assignments.sum("point_total")
  end

  def active?
    status == true
  end

  def student_weighted?
    total_assignment_weight.to_i > 0
  end

  def assignment_weight_open?
    assignment_weight_close_at.nil? || assignment_weight_close_at > Time.now
  end

  def team_roles?
    team_roles == true
  end

  def has_submissions?
    accepts_submissions == true
  end

  def element_for_score(score)
    grade_scheme_elements.where("low_range <= ? AND high_range >= ?", score, score).first
  end

  def grade_level_for_score(score)
    element_for_score(score).try(:level)
  end

  def grade_letter_for_score(score)
    element_for_score(score).try(:letter)
  end

  def membership_for_student(student)
    course_memberships.detect { |m| m.user_id == student.id }
  end

  def assignment_weight_for_student(student)
    student.assignment_weights.where(course_id: self.id).pluck("weight").sum
  end

  def assignment_weight_spent_for_student(student)
    assignment_weight_for_student(student) >= total_assignment_weight.to_i
  end

  def score_for_student(student)
    course_memberships.where(user_id: student).first.score
  end

  # Descriptive stats of the grades
  def minimum_course_score
    CourseMembership.where(course: self, auditing: false,
      role: "student").minimum("score")
  end

  def maximum_course_score
    CourseMembership.where(course: self, auditing: false,
      role: "student").maximum("score")
  end

  def average_course_score
    CourseMembership.where(course: self, auditing: false,
      role: "student").average("score").to_i
  end

  def student_count
    students.count
  end

  def graded_student_count
    students_being_graded.count
  end

  def groups_to_review_count
    groups.pending.count
  end

  def point_total_for_challenges
    challenges.pluck("point_total").sum
  end

  def recalculate_student_scores
    ordered_student_ids.each do |student_id|
      ScoreRecalculatorJob.new(user_id: student_id, course_id: self.id).enqueue
    end
  end

  def ordered_student_ids
    User
      .unscoped # clear the default scope
      .joins(:course_memberships)
      .where("course_memberships.course_id = ? and course_memberships.role = ?", self.id, "student")
      .select(:id) # only need the ids, please
      .order("id ASC")
      .collect(&:id)
  end

  # badges
  def course_badge_count
    badges.count
  end

  def awarded_course_badge_count
    earned_badges.count
  end

  def max_more_than_min
    if (max_group_size? && min_group_size?) && (max_group_size < min_group_size)
      errors.add :base, "Maximum group size must be greater than minimum group size."
    end
  end

  private

  def create_admin_memberships
    User.where(admin: true).each do |admin|
      CourseMembership.create course_id: self.id, user_id: admin.id, role: "admin"
    end
  end

end
