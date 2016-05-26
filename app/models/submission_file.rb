class SubmissionFile < ActiveRecord::Base
  include S3Manager::Carrierwave
  include Historical

  attr_accessible :file, :filename, :filepath, :submission_id, :file_missing,
    :last_confirmed_at

  belongs_to :submission

  mount_uploader :file, AttachmentUploader
  process_in_background :file
  has_paper_trail ignore: [:file_missing, :file_processing, :last_confirmed_at]

  validates :filename, presence: true, length: { maximum: 60 }
  validates :file, file_size: { maximum: 40.megabytes.to_i }

  scope :unconfirmed, -> { where("last_confirmed_at is null") }
  scope :confirmed, -> { where("last_confirmed_at is not null") }
  scope :missing, -> { where(file_missing: true) }
  scope :present, -> { where(file_missing: false) }

  def s3_manager
    @s3_manager ||= S3Manager::Manager.new
  end

  def mark_file_missing
    update_attributes file_missing: true, last_confirmed_at: Time.now
  end

  def check_and_set_confirmed_status
    update_attributes file_missing: file_missing?, last_confirmed_at: Time.now
  end

  def file_missing?
    !exists_on_storage?
  end

  def exists_on_storage?
    S3Manager::Manager::ObjectSummary.new(s3_object_file_key, s3_manager).exists?
  end

  def course
    submission.course
  end

  def assignment
    submission.assignment
  end

  def owner_name
    if submission.assignment.grade_scope == "Group"
      submission.group.name.gsub(/\s/, "-")
    else
      "#{submission.student.last_name}-#{submission.student.first_name}"
    end
  end

  def extension
    File.extname(filename)
  end
end
