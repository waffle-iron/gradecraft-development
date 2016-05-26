class UploadsController < ApplicationController
  before_filter :fetch_upload_with_model, only: :remove

  def remove
    @upload.delete_from_s3

    if @upload.exists_on_s3?
      flash[:alert] = "File failed to delete from the server."
    else
      destroy_upload_with_flash
    end

    redirect_to :back
  end

  protected

  def fetch_upload_with_model
    @upload = upload_class.find params[:upload_id].to_i
  end

  def upload_class
    params[:model].classify.constantize
  end

  def destroy_upload_with_flash
    if @upload.destroy # destroy the actual persisted active record resource
      flash[:success] = "File was successfully removed from the server and deleted."
    else
      flash[:alert] = "File was deleted from the server but the corresponding record could not be destroyed."
    end
  end
end
