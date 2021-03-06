class BadgeFile < ActiveRecord::Base
  include S3Manager::Carrierwave

  belongs_to :badge, inverse_of: :badge_files

  validates :filename, presence: true, length: { maximum: 50 }

  mount_uploader :file, AttachmentUploader
  process_in_background :file

  def course
    badge.course
  end
end
