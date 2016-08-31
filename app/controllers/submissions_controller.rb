class SubmissionsController < ApplicationController
  before_filter :ensure_staff?, only: [:show, :destroy]
  before_filter :save_referer, only: [:new, :edit]

  def show
    presenter = Submissions::ShowPresenter.new(presenter_attrs_with_id)
    authorize! :read, presenter.submission
    render :show, locals: { presenter: presenter }
  end

  def new
    presenter = Submissions::NewPresenter.new(base_presenter_attrs)
    render :new, presenter.render_options
  end

  def create
    assignment = current_course.assignments.find(params[:assignment_id])
    submission = assignment.submissions.new(submission_params.merge(submitted_at: DateTime.now))
    if submission.save
      submission.check_and_set_late_status!
      redirect_to = (session.delete(:return_to) || assignment_path(assignment))
      if current_user_is_student?
        NotificationMailer.successful_submission(submission.id).deliver_now if assignment.is_individual?
        redirect_to_path = assignment_path(assignment)
      end
      flash[:success] = "#{assignment.name} was successfully submitted."
      redirect_to redirect_to_path
    else
      render :new, Submissions::NewPresenter.build(assignment_id: params[:assignment_id],
                                                submission: submission,
                                                student: submission.student,
                                                course: current_course,
                                                group_id: submission.group_id,
                                                view_context: view_context)
    end
  end

  def edit
    presenter = Submissions::EditPresenter.new(presenter_attrs_with_id)
    authorize! :update, presenter.submission
    render :edit, locals: { presenter: presenter }
  end

  def update
    assignment = current_course.assignments.find(params[:assignment_id])
    submission = assignment.submissions.find(params[:id])

<<<<<<< HEAD
    respond_to do |format|
      if submission.update_attributes(submission_params.merge(submitted_at: DateTime.now))
        submission.check_and_set_late_status!
        path = assignment.has_groups? ? { group_id: submission.group_id } :
          { student_id: submission.student_id }
        redirect_to = assignment_submission_path(assignment, submission, path)
        if current_user_is_student?
          NotificationMailer.updated_submission(submission.id).deliver_now if assignment.is_individual?
          redirect_to = assignment_path(assignment, anchor: "tab3")
        end
        format.html { redirect_to redirect_to, notice: "Your submission for #{assignment.name} was successfully updated." }
        format.json { render json: assignment, status: :created, location: assignment }
      else
        format.html do
          render :edit, Submissions::EditPresenter.build(id: params[:id],
                                                      assignment_id: params[:assignment_id],
                                                     course: current_course,
                                                     group_id: submission.group_id,
                                                     submission: submission,
                                                     view_context: view_context)
        end
        format.json { render json: submission.errors, status: :unprocessable_entity }
=======
    if submission.update_attributes(submission_params.merge(submitted_at: DateTime.now))
      path = assignment.has_groups? ? { group_id: submission.group_id } :
        { student_id: submission.student_id }
      redirect_to_path = assignment_submission_path(assignment, submission, path)
      if current_user_is_student?
        NotificationMailer.updated_submission(submission.id).deliver_now if assignment.is_individual?
        redirect_to_path = assignment_path(assignment, anchor: "tab3")
>>>>>>> Refactored alerts
      end
      flash[:success] ="Your submission for #{assignment.name} was successfully updated."
      redirect_to redirect_to_path
    else
      render :edit, Submissions::EditPresenter.build(id: params[:id],
                                                  assignment_id: params[:assignment_id],
                                                 course: current_course,
                                                 group_id: submission.group_id,
                                                 submission: submission,
                                                 view_context: view_context)
    end
  end

  def destroy
    assignment = current_course.assignments.find(params[:assignment_id])
    assignment.submissions.find(params[:id]).destroy
    redirect_to assignment_path(assignment, notice: "Submission deleted")
  end

  private

  def presenter_attrs_with_id
    base_presenter_attrs.merge id: params[:id]
  end

  def base_presenter_attrs
    {
      assignment_id: params[:assignment_id],
      course: current_course,
      group_id: params[:group_id],
      view_context: view_context
    }
  end

  def submission_params
    params.require(:submission).permit :assignment_id, :assignment_type_id,
      :group_id, :link, :student_id, :creator_id, :text_comment, :submitted_at,
      :course_id, :released_at, :submission_file_ids, submission_files_attributes: [:id, file: []]
  end
end
