class SubmissionsController < ApplicationController
  before_filter :ensure_staff?, only: [:show, :destroy]
  before_filter :save_referer, only: [:new, :edit]

  def show
    presenter = Submissions::ShowPresenter.new({ id: params[:id],
                                              assignment_id: params[:assignment_id],
                                              course: current_course,
                                              view_context: view_context })
    authorize! :read, presenter.submission
    render :show, locals: { presenter: presenter }
  end

  def new
    render :new, Submissions::NewPresenter.build(assignment_id: params[:assignment_id],
                                              course: current_course,
                                              group_id: params[:group_id],
                                              view_context: view_context)
  end

  def create
    assignment = current_course.assignments.find(params[:assignment_id])
    submission = assignment.submissions.new(params[:submission].merge(submitted_at: DateTime.now))
    if submission.save
      redirect_to = (session.delete(:return_to) || assignment_path(assignment))
      if current_user_is_student?
        NotificationMailer.successful_submission(submission.id).deliver_now if assignment.is_individual?
        redirect_to = assignment_path(assignment, anchor: "tab3")
      end
      redirect_to redirect_to, notice: "#{assignment.name} was successfully submitted." and return
    end
    render :new, Submissions::NewPresenter.build(assignment_id: params[:assignment_id],
                                              submission: submission,
                                              student: submission.student,
                                              course: current_course,
                                              group_id: submission.group_id,
                                              view_context: view_context)
  end

  def edit
    presenter = Submissions::EditPresenter.new(id: params[:id], assignment_id: params[:assignment_id],
                                            course: current_course, group_id: params[:group_id],
                                            view_context: view_context)
    authorize! :update, presenter.submission
    render :edit, locals: { presenter: presenter }
  end

  def update
    assignment = current_course.assignments.find(params[:assignment_id])
    submission = assignment.submissions.find(params[:id])

    respond_to do |format|
      if submission.update_attributes(params[:submission].merge(submitted_at: DateTime.now))
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
      end
    end
  end

  def destroy
    assignment = current_course.assignments.find(params[:assignment_id])
    assignment.submissions.find(params[:id]).destroy
    redirect_to assignment_path(assignment, notice: "Submission deleted")
  end
end
