class SubmissionsExportPerformer < ResqueJob::Performer
  require "fileutils" # need this for mkdir_p
  require "open-uri" # need this for getting the S3 file over http
  include ModelAddons::ImprovedLogging # log errors with attributes

  attr_reader :submissions_export, :professor, :course, :errors

  def setup
    ensure_s3fs_tmp_dir if use_s3fs?
    @submissions_export = SubmissionsExport.find @attrs[:submissions_export_id]
    fetch_assets
    @submissions_export.update_attributes submissions_export_attributes
    @errors = []
  end

  # perform() attributes assigned to @attrs in the ResqueJob::Base class
  def do_the_work
    if work_resources_present?
      run_performer_steps
      deliver_outcome_mailer
      @submissions_export.update_export_completed_time
    else
      if logger
        log_error_with_attributes "@assignment.present? and/or @students.present? failed and both should have been present, could not do_the_work"
      end
    end
  end

  def performer_steps
    [
      :generate_export_csv, # generate the csv overview for the assignment or team
      :confirm_export_csv_integrity, # check whether the csv export was successful
      :create_student_directories, # generate student directories
      :student_directories_created_successfully, # check whether the student directories were all created successfully
      :create_submission_text_files, # create text files in each student directory if there is submission data that requires it
      :create_submission_binary_files, # create binary files in each student directory
      :write_note_for_missing_binary_files,
      :remove_empty_student_directories,
      :generate_error_log, # write error log for errors that may have occurred during file generation
      :archive_exported_files,
      :upload_archive_to_s3,
      :check_s3_upload_success
    ]
  end

  def run_performer_steps
    performer_steps.each {|step_name| run_step(step_name) }
  end

  def run_step(step_name)
    require_success(send("#{step_name}_messages"), max_result_size: 250) do
      send(step_name)
      @submissions_export.update_attributes step_name => true
    end
  end

  def submissions_export_attributes
    if @submissions_export.last_export_started_at
      base_export_attributes.merge(clear_progress_attributes)
    else
      base_export_attributes
    end
  end

  def base_export_attributes
    {
      student_ids: @students.collect(&:id),
      submissions_snapshot: submissions_snapshot,
      export_filename: "#{export_file_basename}.zip",
      last_export_started_at: Time.now
    }
  end

  def attributes
    base_export_attributes
  end

  def clear_progress_attributes
    performer_steps.inject({}) do |memo, step|
      memo[step] = nil
      memo
    end
  end

  protected

  def work_resources_present?
    @assignment.present? && @students.present?
  end

  def fetch_assets
    @assignment = @submissions_export.assignment
    @course = @submissions_export.course
    @professor = @submissions_export.professor
    @team = @submissions_export.team
    @students = fetch_students
    @students_for_csv = fetch_students_for_csv
    @submissions = fetch_submissions
  end

  def team_present?
    @submissions_export[:team_id].present?
  end

  def s3_manager
    @s3_manager ||= @submissions_export.s3_manager || S3Manager::Manager.new
  end

  def tmp_dir
    if use_s3fs?
      @tmp_dir ||= Dir.mktmpdir(nil, s3fs_tmp_dir_path)
    else
      @tmp_dir ||= Dir.mktmpdir
    end
  end

  def archive_root_dir
    @archive_root_dir ||= FileUtils.mkdir_p(archive_root_dir_path).first
  end

  def archive_root_dir_path
    @archive_root_dir_path ||= File.expand_path(export_file_basename, tmp_dir)
  end

  def csv_file_path
    @csv_file_path ||= File.expand_path("_grade_import_template.csv", archive_root_dir)
  end

  def sorted_student_directory_keys
    submissions_grouped_by_student.keys.sort
  end

  def submissions_grouped_by_student
    @submissions_grouped_by_student ||= @submissions.group_by do |submission|
      student_directory_names[submission.student.id]
    end
  end

  def submissions_snapshot
    @submissions_snapshot ||= @submissions.inject({}) do |memo, submission|
      memo[submission.id] = {
        student_id: submission.student_id,
        updated_at: submission.updated_at.to_s
      }
      memo
    end
  end

  # methods for building and formatting the archive filename
  def export_file_basename
    @export_file_basename ||= "#{archive_basename} - #{filename_timestamp}".gsub("\s+"," ")
  end

  def filename_timestamp
    filename_time.strftime("%Y-%m-%d - %l%M%p").gsub("\s+"," ")
  end

  def filename_time
    Time.zone = @course.time_zone
    @filename_time ||= Time.zone.now
  end

  def archive_basename
    if team_present?
      "#{formatted_assignment_name} - #{formatted_team_name}"
    else
      formatted_assignment_name
    end
  end

  def formatted_assignment_name
    formatted_filename_fragment(@assignment.name)
  end

  def formatted_team_name
    formatted_filename_fragment(@team.name)
  end

  def formatted_filename_fragment(fragment)
    titleize_filename(fragment)
  end

  def titleize_filename(filename)
    filename
      .downcase
      .gsub(/[^\w\s_\:-]+/, " ") # strip out characters besides letters and digits
      .gsub(/_+/, " ") # replace underscores with spaces
      .gsub(/ +/, " ") # replace underscores with spaces
      .gsub(/^ +/, "") # remove leading spaces
      .gsub(/ +$/, "") # remove trailing spaces
      .titleize
  end

  def sanitize_filename(filename)
    filename
      .downcase
      .gsub(/[^\w\s_\:-]+/, "") # strip out characters besides letters and digits
      .gsub(/(^|\b\s)\s+($|\s?\b)/, "\\1\\2") # remove extra spaces
      .gsub(/\s+/, "_") # replace spaces with underscores
      .gsub(/^_+/, "") # remove leading underscores
      .gsub(/_+$/, "") # remove trailing underscores
  end

  def fetch_course
    @course = @assignment.course
  end

  def fetch_students_for_csv
    if team_present?
      @students_for_csv = User.students_by_team(@course, @team)
    else
      @students_for_csv = User.with_role_in_course("student", @course)
    end
  end

  def fetch_students
    if team_present?
      @students = @assignment.students_with_text_or_binary_files_on_team(@team)
    else
      @students = @assignment.students_with_text_or_binary_files
    end
  end

  def fetch_submissions
    if team_present?
      @submissions = @assignment.student_submissions_with_files_for_team(@team)
    else
      @submissions = @assignment.student_submissions_with_files
    end
  end

  def fetch_assignment
    @assignment = Assignment.find @attrs[:assignment_id]
  end

  def fetch_team
    @team = Team.find @submissions_export[:team_id]
  end

  def fetch_professor
    @professor = User.find @attrs[:professor_id]
  end

  def generate_export_csv
    open(csv_file_path, "w") do |f|
      f.puts @assignment.grade_import(@students_for_csv)
    end
  end

  def confirm_export_csv_integrity
    @confirm_export_csv_integrity ||= File.exist?(csv_file_path)
  end

  # final archive concerns

  # create a separate tmp dir for storing the final generated archive
  def ensure_s3fs_tmp_dir
    FileUtils.mkdir_p(s3fs_tmp_dir_path) unless Dir.exist?(s3fs_tmp_dir_path)
  end

  def archive_tmp_dir
    if use_s3fs?
      @archive_tmp_dir ||= Dir.mktmpdir(nil, s3fs_tmp_dir_path)
    else
      @archive_tmp_dir ||= Dir.mktmpdir
    end
  end

  def tmp_dir_parent_path
    use_s3fs? ? s3fs_tmp_dir_path : nil
  end

  def s3fs_tmp_dir_path
    "/s3mnt/tmp/#{Rails.env}"
  end

  def use_s3fs?
    @use_s3fs ||= Rails.env.staging? || Rails.env.production?
  end

  def expanded_archive_base_path
    @expanded_archive_base_path ||= File.expand_path(export_file_basename, archive_tmp_dir)
  end

  ## creating student directories

  def student_directories_created_successfully
    missing_student_directories.empty?
  end

  def missing_student_directories
    @students.inject([]) do |memo, student|
      memo << student_directory_names[student.id] unless Dir.exist?(student_directory_path(student))
      memo
    end
  end

  # in the format of { student_id => "lastname_firstname(--username-if-naming-conflict)" }
  def student_directory_names
    @student_directory_names ||= @students.inject({}) do |memo, student|
      # check to see whether there are any duplicate student names
      total_students_with_name = @students.to_a.count do |compared_student|
        student.same_name_as?(compared_student)
      end

      if total_students_with_name > 1
        memo[student.id] = student.student_directory_name_with_username
      else
        memo[student.id] = student.student_directory_name
      end
      memo
    end
  end

  def create_student_directories
    @students.each do |student|
      dir_path = student_directory_path(student)
      FileUtils.mkdir_p(dir_path) # unless Dir.exist?(dir_path) # create directory with parents
    end
  end

  # removing student directories
  def remove_empty_student_directories
    @students.each do |student|
      if student_directory_empty?(student)
        Dir.delete student_directory_path(student)
      end
    end
  end

  def student_directory_empty?(student)
    (Dir.entries(student_directory_path(student)) - %w{ . .. }).empty?
  end

  def student_directory_path(student)
    File.expand_path(student_directory_names[student.id], archive_root_dir)
  end

  def create_submission_text_files
    @submissions.each do |submission|
      if submission.text_comment.present? || submission.link.present? # write the text file for the submission into the student export directory
        create_submission_text_file(submission)
      end
    end
  end

  def create_submission_text_file(submission)
    open(submission_text_file_path(submission.student), "w") do |f|
      f.puts "Submission items from #{submission.student.last_name}, #{submission.student.first_name}"

      if submission.text_comment.present?
        f.puts "\ntext comment: #{submission.text_comment}"
      end

      if submission.link.present?
        f.puts "\nlink: #{submission.link}"
      end
    end
  end

  def submission_text_file_path(student)
    File.expand_path(submission_text_filename(student), student_directory_path(student))
  end

  def submission_text_filename(student)
    [ formatted_student_name(student), formatted_assignment_name, "Submission Text.txt" ].join(" - ")
  end

  # @mz todo: update specs
  def formatted_student_name(student)
    titleize_filename student.full_name
  end

  def create_submission_binary_files
    @submissions.each do |submission|
      if submission.submission_files.present?
        submission.process_unconfirmed_files if submission.submission_files.unconfirmed.count > 0
        create_binary_files_for_submission(submission)
      end
    end
  end

  def missing_binaries_file_path
    File.expand_path("missing_files.txt", archive_root_dir)
  end

  def submission_files_with_missing_binaries
    @submission_files_with_missing_binaries ||= @assignment.submission_files_with_missing_binaries
  end

  def students_with_missing_binaries
    @students_with_missing_binaries ||= @assignment.students_with_missing_binaries
  end

  # @mz todo: update specs
  def write_note_for_missing_binary_files
    unless students_with_missing_binaries.empty?
      open(missing_binaries_file_path, "wt") do |file|
        write_missing_binary_text(file)
      end
    end
  end

  def write_missing_binary_text(file)
    file.puts "The following files were uploaded, but no longer appear to be available on the server:"
    write_missing_binary_files_for_student(file)
  end

  def write_missing_binary_files_for_student(file)
    students_with_missing_binaries.each_with_index do |student, index|
      file.puts "\n#{student.full_name}:"
      add_missing_binary_filenames_to_file(file, student)
    end
  end

  def add_missing_binary_filenames_to_file(file, student)
    submission_files_with_missing_binaries.each do |missing_file|
      file.puts "#{missing_file.filename}" if missing_file.submission.student_id == student.id
    end
  end

  def create_binary_files_for_submission(submission)
    submission.submission_files.present.each_with_index do |submission_file, index|
      write_submission_binary_file(submission.student, submission_file, index)
    end
  end

  def student_directory_file_path(student, filename)
    File.expand_path(filename, student_directory_path(student))
  end

  def submission_binary_file_path(student, submission_file, index)
    filename = submission_binary_filename(student, submission_file, index)
    student_directory_file_path(student, filename)
  end

  def submission_binary_filename(student, submission_file, index)
    [ formatted_student_name(student), formatted_assignment_name, "Submission File #{index + 1}"].join(" - ") + submission_file.extension
  end

  def write_submission_binary_file(student, submission_file, index)
    file_path = submission_binary_file_path(student, submission_file, index)
    stream_s3_file_to_disk(submission_file, file_path)
  end

  def stream_s3_file_to_disk(submission_file, target_file_path)
    begin
      s3_manager.write_s3_object_to_disk(submission_file.s3_object_file_key, target_file_path)
    rescue Aws::S3::Errors::NoSuchKey
      submission_file.mark_file_missing
    end
  end

  def remove_if_exists(file_path)
    File.delete file_path if File.exist? file_path
  end

  def binary_file_error_message(message, student, submission_file, error_io)
    "#{message}. "\
    "Student ##{student.id}: #{student.last_name}, #{student.first_name}, " \
    "SubmissionFile ##{submission_file.id}: #{submission_file.filename}, " \
    "error: #{error_io}"
  end

  def generate_error_log
    return if errors.empty?
    open(error_log_path, "w") {|file| file.puts errors }
  end

  def error_log_path
    File.expand_path("error_log.txt", archive_root_dir)
  end

  # archive export directory
  def archive_exported_files
    Archive::Zip.archive("#{expanded_archive_base_path}.zip", archive_root_dir)
  end

  def upload_archive_to_s3
    @submissions_export.upload_file_to_s3("#{expanded_archive_base_path}.zip")
  end

  def check_s3_upload_success
    @check_s3_upload_success ||= @submissions_export.s3_object_exists?
  end

  private

  def deliver_outcome_mailer
    if check_s3_upload_success
      deliver_archive_success_mailer
    else
      deliver_archive_failed_mailer
    end
  end

  def deliver_archive_success_mailer
    if @team
      deliver_team_export_successful_mailer
    else
      deliver_export_successful_mailer
    end
  end

  def deliver_archive_failed_mailer
    @team ? deliver_team_export_failure_mailer : deliver_export_failure_mailer
  end

  def deliver_export_successful_mailer
    ExportsMailer.submissions_export_success(professor, @assignment, \
      @submissions_export, secure_token).deliver_now
  end

  def deliver_team_export_successful_mailer
    ExportsMailer.team_submissions_export_success(professor, @assignment, \
      @team, @submissions_export, secure_token).deliver_now
  end

  def deliver_export_failure_mailer
    ExportsMailer.submissions_export_failure(@professor, @assignment)
      .deliver_now
  end

  def deliver_team_export_failure_mailer
    ExportsMailer.team_submissions_export_failure(@professor, @assignment, \
      @team).deliver_now
  end

  def secure_token
    # be sure to add the user_id and course_id here in the event that we'd like
    # to revoke the secure token later in the event that, say, the staff member
    # is removed from the course or from the system
    #
    # also let's cache this to make sure that there are never any more generated
    # than absolutely need to be
    #
    @secure_token ||= SecureToken.create(
      user_id: professor[:id],
      course_id: course[:id],
      target: submissions_export
    )
  end

  def expand_messages(messages={})
    {
      success: [ messages[:success], message_suffix ].join(" "),
      failure: [ messages[:failure], message_suffix ].join(" ")
    }
  end

  def generate_export_json_messages
    expand_messages ({
      success: "Successfully generated the export JSON",
      failure: "Failed to generate the export JSON"
    })
  end

  def generate_export_csv_messages
    expand_messages({
      success: "Successfully generated the csv data",
      failure: "Failed to generate the csv data"
    })
  end

  def confirm_export_csv_integrity_messages
    expand_messages ({
      success: "Successfully saved the CSV file on disk",
      failure: "Failed to save the CSV file on disk"
    })
  end

  def create_student_directories_messages
    expand_messages ({
      success: "Successfully created the student directories",
      failure: "Failed to create the student directories"
    })
  end

  def write_note_for_missing_binary_files_messages
    expand_messages ({
      success: "Successfully wrote the note for missing binary files",
      failure: "Failed to write the missing binary files note"
    })
  end

  def student_directories_created_successfully_messages
    expand_messages ({
      success: "Successfully confirmed creation of all student directories",
      failure: "Some student directories did not create properly"
    })
  end

  def create_submission_text_files_messages
    expand_messages ({
      success: "Successfully created all text files for the student submissions",
      failure: "Student submission text files did not create properly"
    })
  end

  def create_submission_binary_files_messages
    expand_messages ({
      success: "Successfully created all binary files for the student submissions",
      failure: "Student submission binary files did not create properly"
    })
  end

  def generate_error_log_messages
    expand_messages ({
      success: "Successfully generated an error log for binary file creation if one was required",
      failure: "Failed to build an error log for binary file creation errors"
    })
  end

  def archive_exported_files_messages
    expand_messages ({
      success: "Successfully generated an archive containing the exported assignment files",
      failure: "Failed to generate an archive containing the exported assignment files"
    })
  end

  def upload_archive_to_s3_messages
    expand_messages ({
      success: "Successfully uploaded the submissions archive to S3",
      failure: "Failed to upload the submissions archive to S3"
    })
  end

  def remove_empty_student_directories_messages
    expand_messages ({
      success: "Successfully removed empty student directories from archive",
      failure: "Failed to remove empty student directories"
    })
  end

  def check_s3_upload_success_messages
    expand_messages ({
      success: "Successfully confirmed that the exported archive was uploaded to S3",
      failure: "Failed to confirm that the exported archive was uploaded to S3. ObjectSummary#exists? failed on the object instance."
    })
  end

  def message_suffix
    "for assignment #{@assignment.id} for students: #{@students.collect(&:id)}"
  end
end
