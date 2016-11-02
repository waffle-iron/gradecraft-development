class User < ActiveRecord::Base
  authenticates_with_sorcery!

  class << self
    def with_role_in_course(role, course)
      if role == "staff"
        user_ids = CourseMembership.where("course_id=? AND (role=? OR role=?)", course, "professor", "gsi").pluck(:user_id)
      else
        user_ids = CourseMembership.where(course: course, role: role).pluck(:user_id)
      end
      User.where(id: user_ids)
    end

    Role.all.each do |role|
      define_method(role.pluralize) do |course|
        with_role_in_course(role,course)
      end
    end

    def students_being_graded(course, team=nil)
      user_ids = CourseMembership.where(course: course, role: "student", auditing: false).pluck(:user_id)
      query = User.where(id: user_ids)
      query = query.students_in_team(team.id, user_ids) if team
      query
    end

    def students_by_team(course, team)
      user_ids = CourseMembership.where(course: course, role: "student").pluck(:user_id)
      User.where(id: user_ids).students_in_team(team.id, user_ids)
    end

    def unscoped_students_being_graded_for_course(course, team=nil)
      query = User
        .unscoped # override the order("last_name ASC") default scope on the User model
        .select("users.id, users.first_name, users.last_name, users.email, users.display_name, users,avatar_file_name, users.updated_at, course_memberships.score as cached_score_sql_alias")
        .joins("INNER JOIN course_memberships ON course_memberships.user_id = users.id")
        .where("course_memberships.course_id = ?", course.id)
        .where("course_memberships.auditing = ?", false)
        .where("course_memberships.role = ?", "student")
        .includes(:course_memberships)
        .group("users.id, course_memberships.score")
        .includes(:team_memberships)
      query = query.joins("INNER JOIN team_memberships ON team_memberships.student_id = users.id")
          .where("team_memberships.team_id = ?", team.id) if team
      query
    end

    def internal_email_regex
      /(\.|@)umich\.edu$/
    end
  end

  attr_accessor :password, :password_confirmation, :cached_last_login_at,
    :score, :team

  # all student display pages are ordered by last name except for the
  # leaderboard, and top 10/bottom 10
  default_scope { order("last_name ASC, first_name ASC") }

  scope :order_by_high_score, -> { includes(:course_memberships).order "course_memberships.score DESC" }
  scope :order_by_low_score, -> { includes(:course_memberships).order "course_memberships.score ASC" }
  scope :students_in_team, -> (team_id, student_ids) \
    { includes(:team_memberships).where(team_memberships: { team_id: team_id, student_id: student_ids }) }

  scope :order_by_name, -> { order("last_name, first_name ASC") }

  mount_uploader :avatar_file_name, ImageUploader

  has_many :authorizations, class_name: "UserAuthorization", dependent: :destroy
  has_many :course_memberships, dependent: :destroy, inverse_of: :user
  has_many :courses, through: :course_memberships
  has_many :course_users, through: :courses, source: "users"
  accepts_nested_attributes_for :courses
  accepts_nested_attributes_for :course_memberships, allow_destroy: true

  belongs_to :current_course, class_name: "Course", touch: true

  has_many :assignments, through: :grades

  has_many :unlock_states, foreign_key: :student_id, dependent: :destroy

  has_many :assignment_type_weights, foreign_key: :student_id

  has_many :submissions, foreign_key: :student_id, dependent: :destroy
  has_many :created_submissions, as: :creator

  has_many :grades, foreign_key: :student_id, dependent: :destroy
  has_many :predicted_earned_grades, foreign_key: :student_id, dependent: :destroy
  has_many :predicted_earned_badges, foreign_key: :student_id, dependent: :destroy
  has_many :predicted_earned_challenges, foreign_key: :student_id, dependent: :destroy
  has_many :graded_grades, foreign_key: :graded_by_id, class_name: "Grade"
  has_many :criterion_grades, foreign_key: :student_id, dependent: :destroy

  has_many :imported_users, dependent: :destroy

  has_many :earned_badges, foreign_key: :student_id, dependent: :destroy
  has_many :awarded_badges, foreign_key: :awarded_by_id, class_name: 'EarnedBadge'

  accepts_nested_attributes_for :earned_badges, reject_if: proc { |attributes| attributes["earned"] != "1" }
  has_many :badges, through: :earned_badges

  has_many :group_memberships, foreign_key: :student_id, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :assignment_groups, through: :groups

  has_many :team_memberships, foreign_key: :student_id, dependent: :destroy
  has_many :team_leaderships, foreign_key: :leader_id, dependent: :destroy
  has_many :teams, through: :team_memberships do
    def set_for_course(course_id, ids)
      other_team_ids = proxy_association.owner.teams.where("course_id != ?", course_id).pluck(:id)
      if proxy_association.owner.role(Course.find(course_id)) == "student"
        proxy_association.owner.team_ids = other_team_ids | [ids]
      else
        if ids.present?
          proxy_association.owner.team_ids = other_team_ids | ids
        end
      end
    end
  end

  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :username, presence: true,
                    length: { maximum: 50 }
  validates :email, presence: true,
                    format: { with: email_regex },
                    uniqueness: { case_sensitive: false }

  validates :first_name, :last_name, presence: true
  validates :password, confirmation: true
  validates :password_confirmation, presence: true, if: :password, on: :update
  validates :email, internal_email: { format: internal_email_regex, name: "University of Michigan" }

  def internal?
    @internal || email_was =~ self.class.internal_email_regex
  end

  def internal=(value)
    @internal = value
  end

  def self.find_or_create_by_lti_auth_hash(auth_hash)
    criteria = { email: auth_hash["extra"]["raw_info"]["lis_person_contact_email_primary"] }
    where(criteria).first || create!(criteria) do |u|
      u.lti_uid = auth_hash["extra"]["raw_info"]["lis_person_sourcedid"]
      u.first_name = auth_hash["extra"]["raw_info"]["lis_person_name_given"]
      u.last_name = auth_hash["extra"]["raw_info"]["lis_person_name_family"]
      email = auth_hash["extra"]["raw_info"]["lis_person_contact_email_primary"]
      username = email.split("@")[0]
      u.username = username
      u.kerberos_uid = username
    end
  end

  def self.find_by_kerberos_auth_hash(auth_hash)
    where(kerberos_uid: auth_hash["uid"]).first
  end

  def self.find_by_insensitive_email(email)
    where("LOWER(email) = :email", email: email.downcase).first
  end

  def self.find_by_insensitive_username(username)
    where("LOWER(username) = :username", username: username.downcase).first
  end

  def self.email_exists?(email)
    !!find_by_insensitive_email(email)
  end

  def activated?
    activation_state == "active"
  end

  def name
    @name = [first_name,last_name].reject(&:blank?).join(" ").presence || "User #{id}"
  end

  def submitter_directory_name
    "#{last_name.camelize}, #{first_name.camelize}"
  end

  def submitter_directory_name_with_suffix
    "#{student_directory_name} - #{username.camelize}"
  end

  def same_name_as?(another_user)
    name.downcase == another_user.name.downcase
  end

  def auditing_course?(course)
    course.membership_for_student(self).auditing?
  end

  Role.all.each do |role|
    define_method("is_#{role}?") do |course|
      self.role(course) == role
    end
  end

  def role(course)
    return "admin" if self.admin?
    membership = self.course_memberships.where(course_id: course.id).first
    membership.role if membership
  end

  def is_staff?(course)
    is_professor?(course) || is_gsi?(course) || is_admin?(course)
  end

  ### TEAMS
  # Finding a student's team for a course
  def team_for_course(course)
    @team ||= teams.where(course_id: course).first
  end

  # Finding all of the team leaders for a single team
  def team_leaders(course)
    @team_leaders ||= team_for_course(course).leaders rescue nil
  end

  # Finding all of a team leader's teams for a single course
  def team_leaderships_for_course(course)
    team_leaderships.joins(:team).where("teams.course_id = ?", course.id)
  end

  # Space for users to build a narrative around their identity
  def character_profile(course)
    course_memberships.where(course: course).first.try("character_profile")
  end

  def archived_courses
    courses.where(status: false)
  end

  ### SCORE
  def cached_score_for_course(course)
    @cached_score ||= course_memberships.where(course_id: course).first.score || 0 if
      course_memberships.where(course_id: course).first.present?
  end

  # Powers the grade distribution box plot
  def scores_for_course(course)
    user_score = course_memberships.where(course_id: course, auditing: FALSE).pluck("score")
    scores = CourseMembership.where(course: course, role: "student", auditing: false).pluck(:score)
    return {
      scores: scores,
      user_score: user_score
    }
  end

  # Checking to see if a student has any positive predictions for a course
  def predictions_for_course?(course)
    predicted_earned_grades.for_course(course).predicted_to_be_done.present?
  end

  ### EARNED LEVELS AND GRADE LETTERS

  def grade_for_course(course)
    cm = course_memberships.where(course_id: course.id).first
    return cm.grade_scheme_element if cm.grade_scheme_element.present?
    return cm.earned_grade_scheme_element
  end

  def grade_level_for_course(course)
    @grade_level ||= grade_for_course(course).try(:level)
  end

  def grade_letter_for_course(course)
    @grade_letter_for_course ||= grade_for_course(course).try(:letter)
  end

  def get_element_level(course, direction)
    course_elements = course.grade_scheme_elements.order_by_lowest_points.to_a

    current_element = self.grade_for_course(course)
    current_element_index = course_elements.index{ |item| item[:level] == current_element[:level] }

    element = send("#{direction}_element_level", course_elements, current_element_index)
  end

  def next_element_level(course_elements, current_element_index)
    next_element = course_elements[current_element_index + 1] unless current_element_index == (course_elements.size - 1)
  end

  def previous_element_level(course_elements, current_element_index)
    previous_element = course_elements[current_element_index - 1] unless current_element_index == 0
  end

  def points_to_next_level(course)
    get_element_level(course, :next).lowest_points - cached_score_for_course(course)
  end

  ### GRADES

  # Checking specifically if there is a released grade for an assignment
  def grade_released_for_assignment?(assignment)
    grade = grade_for_assignment(assignment)
    GradeProctor.new(grade).viewable?
  end

  def grades_for_course(course)
    grades.where(course: course)
  end

  # Returning all of the grades a student has received this week
  def grades_released_for_course_this_week(course)
    grades = grades_for_course(course).where("updated_at > ? ", 7.days.ago)
    viewable_grades = []
    grades.each do |grade|
      viewable_grades << grade if GradeProctor.new(grade).viewable? && !grade.excluded_from_course_score
    end
    return viewable_grades
  end

  # Returning the total number of points for all grades released this week
  def points_earned_for_course_this_week(course)
    grades_released_for_course_this_week(course).map(&:final_points).compact.sum
  end

  # Grabbing the grade for an assignment
  def grade_for_assignment(assignment)
    grades.where(assignment_id: assignment.id).first || grades.new(assignment: assignment)
  end

  def grade_for_assignment_id(assignment_id)
    grades.where(assignment_id: assignment_id)
  end

  # Powers the worker to recalculate student scores
  def cache_course_score_and_level(course_id)
    course_membership = fetch_course_membership(course_id)
    unless course_membership.nil?
      course_membership.recalculate_and_update_student_score
      course_membership.check_and_update_student_earned_level
    end
  end

  def fetch_course_membership(course_id)
    course_memberships.where(course_id: course_id).first
  end

  ### SUBMISSIONS

  def submission_for_assignment(assignment)
    submissions.where(assignment_id: assignment.id).try(:first)
  end

  ### BADGES

  def earned_badges_for_course(course)
    earned_badges.where(course: course).student_visible
  end

  def earned_badge_score_for_course(course)
    earned_badges_for_course(course).sum(:points)
  end

  # returns all badges a student has earned for a particular course this week
  def earned_badges_for_course_this_week(course)
    earned_badges_for_course(course).where("created_at > ? ", 7.days.ago)
  end

  def earned_badge_for_badge(badge)
    earned_badges.where(badge: badge)
  end

  def earned_badges_for_badge_count(badge)
    earned_badges.where(badge: badge).count
  end

  # Unique badges associated with all of the earned badges for a given
  # student/course combo
  def unique_student_earned_badges(course)
    @unique_student_earned_badges ||= Badge
      .includes(:earned_badges)
      .where("earned_badges.course_id = ?", course[:id])
      .where("earned_badges.student_id = ?", self[:id])
      .where("earned_badges.student_visible = ?", true)
      .references(:earned_badges)
  end

  # Student visible earned badges for a particular badge
  def visible_earned_badges_for_badge(badge)
    EarnedBadge
      .where(badge: badge)
      .where(student_id: self.id)
      .where(student_visible: true)
  end

  # Number of times a student has earned a particular badge
  def visible_earned_badges_for_badge_count(badge)
    self.visible_earned_badges_for_badge(badge).count
  end

  # this should be all earned badges that either:
  # 1) have no associated grade and have been awarded to the student, or...
  # 2) have an associated grade that has been marked graded_or_released?
  # (indicated through the student_visible boolean)
  def student_visible_earned_badges(course)
    @student_visible_earned_badges ||= EarnedBadge
      .includes(:badge)
      .where(course: course)
      .where(student_id: self[:id])
      .where(student_visible: true)
  end

  # this should be all badges that:
  # 1) exist in the current course, in which the student is enrolled, AND:
  # 2) the student has either not earned at all for any grade, or:
  # 3) the student has earned the badge, but multiple are allowed, or:
  # 3) the student has earned the badge, multiple are not allowed, but the
  # earned badge is for the current grade
  def earnable_course_badges_for_grade(grade)
    Badge
      .where(course_id: grade[:course_id])
      .merge(earnable_course_badges(grade))
  end

  # this should be all badges that:
  # 1) exist in the current course, in which the student is enrolled
  # 2) the student has not earned, but is visible & available, or...
  # 3) the student has earned_badge for, but that earned_badge is set to
  # student_visible 'false' <- I think this is incorrect? @ch
  def student_visible_unearned_badges(course)
    Badge
      .where(course_id: course[:id])
      .where(visible: true)
      .where("id not in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ? and earned_badges.student_visible = ?)", self[:id], course[:id], true)
  end

  # Returns the student's assigned weight for an assignment type category
  def weight_for_assignment_type(assignment_type)
    assignment_type_weights.where(assignment_type: assignment_type).first.try(:weight) || 0
  end

  def weight_spent?(course)
    return true if self.total_weight_spent(course) == course.total_weights
    return false
  end

  def total_weight_spent(course)
    total = 0
    course.assignment_types.student_weightable.each do |assignment_type|
      total += self.weight_for_assignment_type(assignment_type)
    end
    return total
  end

  def weighted_assignments?(course)
    assignment_type_weights.where(course: course).count > 0
  end

  # Used to allow students to self-log a grade, currently only a boolean
  # (complete or not)
  def self_reported_done?(assignment)
    grade = grade_for_assignment(assignment)
    GradeProctor.new(grade).viewable?
  end

  ### GROUPS

  def group_for_assignment(assignment)
    assignment_groups.where(assignment: assignment).first.try(:group)
  end

  def has_group_for_assignment?(assignment)
    assignment.has_groups? && group_for_assignment(assignment).present?
  end

  def last_course_login(course)
    course_memberships.where(course: course).first.last_login_at
  end

  private

  def earnable_course_badges(grade)
    Badge
      .unscoped
      .where("(id not in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ?))", self[:id], grade[:course_id])
      .or(Badge.where("(id in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ?) and can_earn_multiple_times = ?)", self[:id], grade[:course_id], true))
      .or(Badge.where("(id in (select distinct(badge_id) from earned_badges where earned_badges.student_id = ? and earned_badges.course_id = ? and earned_badges.grade_id = ?) and can_earn_multiple_times = ?)", self[:id], grade[:course_id], grade[:id], false))
  end
end
