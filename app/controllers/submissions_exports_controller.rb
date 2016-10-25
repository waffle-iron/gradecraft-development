class SubmissionsExportsController < ApplicationController
  before_action :ensure_staff?, except: :secure_download

  skip_before_action :require_login, only: :secure_download
  skip_before_action :increment_page_views, only: :secure_download
  skip_before_action :course_scores, only: :secure_download

  def create
    if create_submissions_export && submissions_export_job.enqueue
      flash[:success] = "Your submissions export is being prepared. You'll receive an email when it's complete."
    else
      flash[:alert] = "Your submissions export failed to build. An administrator has been contacted about the issue."
    end

    redirect_to assignment_path(assignment)
  end

  def destroy
    if submissions_export.delete_object_from_s3
      submissions_export.destroy
      flash[:success] = "Assignment export successfully deleted from server"
    else
      flash[:alert] = "Unable to delete the submissions export from the server"
    end

    redirect_to downloads_path
  end

  def download
    stream_file_from_s3
  end

  def secure_download
    if secure_download_authenticator.authenticates?
      stream_file_from_s3
    else
      if secure_download_authenticator.valid_token_expired?
        flash[:alert] = "The email link you used has expired."
      else
        flash[:alert] = "The link you attempted to access does not exist."
      end
      flash[:alert] += " Please login to download the desired file."

      redirect_to root_url
    end
  end

  protected

  def secure_download_authenticator
    @secure_download_authenticator ||= SecureTokenAuthenticator.new(
      secure_token_uuid: params[:secure_token_uuid],
      secret_key: params[:secret_key],
      target_id: params[:id],
      target_class: "SubmissionsExport"
    )
  end

  def stream_file_from_s3
    send_data submissions_export.stream_s3_object_body, \
      filename: submissions_export.export_filename
  end

  def submissions_export
    @submissions_export ||= SubmissionsExport.find params[:id]
  end

  def create_submissions_export
    @submissions_export = SubmissionsExport.create(
      assignment_id: params[:assignment_id],
      course_id: current_course.id,
      professor_id: current_user.id,
      team_id: params[:team_id]
    )
  end

  def submissions_export_job
    @submissions_export_job ||= SubmissionsExportJob.new(
      submissions_export_id: @submissions_export.id
    )
  end

  def assignment
    @assignment ||= Assignment.find(params[:assignment_id])
  end
end
