class StudentAcademicHistory < ActiveRecord::Base

  belongs_to :student, class_name: "User", foreign_key: :student_id
  belongs_to :course

  attr_accessible :student_id, :major, :gpa, :current_term_credits,
    :accumulated_credits, :year_in_school, :state_of_residence, :high_school,
    :athlete, :act_score, :sat_score, :course_id

  validates :gpa, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates_presence_of :course_id, :student_id

end
