require_relative "../services/cancels_course_membership"

class CourseMembershipsController < ApplicationController
  before_filter :ensure_staff?

  def create
    @course_membership =
      current_course.course_memberships.create(course_membership_params)
    @course_membership.save

    respond_with @course_membership
    expire_action action: :index
  end

  def destroy
    course_membership = current_course.course_memberships.find(params[:id])
    Services::CancelsCourseMembership.for_student course_membership
    
    respond_with course_membership, location: -> { students_path }
  end

  private

  def course_membership_params
    params.require(:course_membership).permit :auditing, :character_profile,
      :course_id, :instructor_of_record, :user_id, :role, :last_login_at,
      :earned_grade_scheme_element_id
  end
end
