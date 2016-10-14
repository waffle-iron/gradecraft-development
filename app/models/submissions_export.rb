require "s3_manager"
require "export"
require "formatter"

class SubmissionsExport < ActiveRecord::Base
  # treat this resource as if it's responsible for managing an object on s3
  # Note that if this record is an ActiveRecord::Base descendant then a
  # callback for :rebuild_s3_object_key is added for on: :save
  #
  include S3Manager::Resource

  # give this resource additional methods that aren't s3-specific but that
  # assist in the export process
  #
  include Export::Model

  belongs_to :course
  belongs_to :professor, class_name: "User", foreign_key: "professor_id"
  belongs_to :team
  belongs_to :group
  belongs_to :assignment

  # secure tokens allow for one-click downloads of the file from an email
  has_many :secure_tokens, as: :target, dependent: :destroy

  validates :course_id, presence: true
  validates :assignment_id, presence: true

  # this should be moved into the Exports::Model module, or a new
  # SecureToken::Target module, but since SecureToken still lives in /app/models
  # it feels weird to have to include an app resource to test /lib
  #
  def generate_secure_token
    SecureToken.create user_id: professor.id, course_id: course.id, target: self
  end

  # tell s3 which directory structure to use for exports
  def s3_object_key_prefix
    "exports/courses/#{course_id}/assignments/#{assignment_id}/" \
      "#{object_key_date}/#{object_key_microseconds}"
  end

  def url_safe_filename
    Formatter::Filename.new("#{export_file_basename}.zip").filename
  end

  # methods for building and formatting the archive filename
  def export_file_basename
    @export_file_basename ||= "#{archive_basename} - #{filename_timestamp}".gsub(/\s+/," ")
  end

  def archive_basename
    [formatted_assignment_name,
     formatted_team_name,
     formatted_group_name].compact.join(" - ").strip
  end

  def formatted_assignment_name
    @formatted_assignment_name ||= Formatter::Filename.titleize assignment.name
  end

  def formatted_team_name
    @team_name ||= Formatter::Filename.titleize(team.name) if team
  end

  def formatted_group_name
    @group_name ||= Formatter::Filename.titleize(group.name) if group
  end
end
