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
    @group = current_course.groups.new(params[:group])
    @group.students << current_student if current_user_is_student?
    if current_user_is_student?
      @group.approved = "Pending"
    else
      @group.approved = "Approved"
    end
    respond_to do |format|
      if @group.save
        format.html { respond_with @group }
        flash[:success]=
          "#{(@group.name).capitalize} #{term_for :group} successfully created"
      else
        @other_students = potential_team_members
        format.html { render action: "new" }
      end
    end
  end

  def edit
    @other_students = potential_team_members
    @title = "Editing #{@group.name}"
  end

  def update
    respond_to do |format|
      if @group.update_attributes(params[:group])
        format.html { respond_with @group }
        flash[:success]=
          "#{@group.name} #{term_for :group} successfully updated"
      else
        @other_students = potential_team_members
        format.html { render action: "edit" }
      end
    end
  end

  def destroy
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_path }
      flash[:success]= "#{@group.name} #{term_for :group} successfully deleted"
    end
  end

  private

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
