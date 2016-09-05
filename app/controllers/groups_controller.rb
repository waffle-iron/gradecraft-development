class GroupsController < ApplicationController
  before_filter :ensure_staff?, only: [:index, :destroy]

  before_action :find_group, only: [:show, :edit, :update, :destroy]
  before_action :find_group_assignments, only: [:new, :edit, :create, :update]

  def index
    groups = current_course.groups
    @pending_groups = groups.pending
    @approved_groups = groups.approved
    @rejected_groups = groups.rejected
    @assignments = current_course.assignments.group_assignments
    @title = current_course.group_term.pluralize
  end

  def show
    @title = "#{@group.name}"
  end

  def new
    @group = current_course.groups.new
    @title = "Start a #{term_for :group}"
    @other_students = potential_team_members
  end

  def create
    @group = current_course.groups.new(group_params)
    @group.students << current_student if current_user_is_student?
    if current_user_is_student?
      @group.approved = "Pending"
    else
      @group.approved = "Approved"
    end
    if @group.save
      respond_with @group
    else
      @other_students = potential_team_members
      render action: "new"
    end
  end

  def edit
    @other_students = potential_team_members
    @title = "Editing #{@group.name}"
  end

  def update
    if @group.update_attributes(group_params)
      respond_with @group
    else
      @other_students = potential_team_members
      render action: "edit"
    end
  end

  def destroy
    @group.destroy
    respond_with groups_path
  end

  private

  def group_params
    params.require(:group).permit :name, :approved, :course_id,
      :text_feedback, :text_proposal, :proposals_attributes, :proposal, :approved,
      proposal_attributes: [:approved, :title, :group_id, :submitted_by, :feedback, :proposal, :id],
      assignment_groups_attributes: [:assignment_id, :group_id, :id],
      group_membership_attributes: [:accepted, :group_id, :student_id, :id, :course_id],
      assignment_ids: [], student_ids: []
  end

  def potential_team_members
    current_course.students.where.not(id: current_user.id)
  end

  def find_group
    @group = current_course.groups.includes(:proposals).find(params[:id])
  end

  def find_group_assignments
    @group_assignments = current_course.assignments.group_assignments
  end

end
