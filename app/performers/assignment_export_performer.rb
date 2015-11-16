class AssignmentExportPerformer < ResqueJob::Performer
  include ModelAddons::ImprovedLogging # log errors with attributes

  def setup
    fetch_assets
  end

  # perform() attributes assigned to @attrs in the ResqueJob::Base class
  def do_the_work
    if work_resources_present?
      require_success(generate_csv_messages, max_result_size: 250) do
        generate_export_csv
      end
    else
      if logger
        log_error_with_attributes "@assignment.present? or @students.present? failed and both should have been present"
      end
    end
  end

  # add this for logging_with_attributes
  def attributes
    { 
      assignment_id: @assignment.try(:id),
      course_id: @course.try(:id),
      professor_id: @professor.try(:id),
      student_ids: @students.collect(&:id),
      team_id: @team.try(:id)
    }
  end

  protected

  def work_resources_present?
    @assignment.present? and @students.present?
  end

  def fetch_assets
    @assignment = fetch_assignment
    @course = fetch_course
    @professor = fetch_professor
    @students = fetch_students
    @team = fetch_team if team_present?
  end

  # @mz todo: add specs
  def team_present?
    @attrs[:team_id].present?
  end

  def tmp_dir
    @tmp_dir ||= Dir.mktmpdir
  end

  def csv_file_path
    @csv_file_path ||= File.expand_path("_grade_import_template.csv", tmp_dir)
  end

  # # entire block handled by submissions and submissions_by_team methods, and by 
  # if params[:team_id].present?
  #   team = current_course.teams.find_by(id: params[:team_id])
  #   @students = current_course.students_being_graded_by_team(team)
  # else
  #   @students = current_course.students_being_graded
  # end
  #

  # @mz todo: add specs
  def archive_basename
    if team_present?
      "#{formatted_assignment_name}_#{formatted_team_name}"
    else
      formatted_assignment_name
    end
  end

  # @mz todo: add specs
  def formatted_assignment_name
    "#{@assignment.name.gsub(/\W+/, "_").downcase[0..20]}"
  end

  # @mz todo: add specs
  def formatted_team_name
    "#{@team.name.gsub(/\W+/, "_").downcase[0..20]}"
  end

  def fetch_course
    @course = @assignment.course
  end

  def fetch_students
    if team_present?
      @students = @course.students_being_graded_by_team(@team)
    else
      @students = @course.students_being_graded
    end
  end

  def fetch_assignment
    @assignment = Assignment.find @attrs[:assignment_id]
  end

  def fetch_team
    @team = Team.find @attrs[:team_id]
  end

  def fetch_professor
    @professor = User.find @attrs[:professor_id]
  end

  # @mz todo: add specs
  def generate_export_csv
    open(csv_file_path, 'w') do |f|
      f.puts @assignment.grade_import(@students)
    end
  end
  
  private

  def submissions_presenter
    @presenter ||= AssignmentExportPresenter.build(
      presenter_base_options.merge(
        submissions: @assignment.student_submissions
      )
    )
  end

  def assignment_export_attributes
    {
      assignment_id: @attrs[:assignment_id],
      team_id: @attrs[:team_id]
    }
  end

  def submissions_by_student_archive_hash
    JbuilderTemplate.new(temp_view_context).encode do |json|
      json.partial! "assignment_exports/submissions_by_student_archive_json", presenter: @presenter
    end.to_json
  end

  def submissions_by_team_presenter
    @presenter ||= AssignmentExportPresenter.build(
      presenter_base_options.merge(
        submissions: @assignment.student_submissions_for_team(@team),
        team: @team
      )
    )
  end

  def submissions_presenter
    @presenter ||= AssignmentExportPresenter.build(
      presenter_base_options.merge(
        submissions: @assignment.student_submissions
      )
    )
  end

  def presenter_base_options
   {
      assignment: @assignment,
      csv_file_path: csv_file_path,
      export_file_basename: export_file_basename
    }
  end

  # rough this in for now, need to pull this from the original method
  def export_file_basename
    "great_basename"
  end

  def deliver_archive_complete_mailer
    ExportsMailer.submissions_archive_complete(@course, @user, @csv_data).deliver_now
  end

  def deliver_team_archive_complete_mailer
    ExportsMailer.submissions_archive_complete(@course, @user, @csv_data).deliver_now
  end

  def generate_csv_messages
    {
      success: "Successfully generated the csv data on assignment #{@assignment.id} for students: #{@students.collect(&:id)}",
      failure: "Failed to generate the csv data on assignment #{@assignment.id} for students: #{@students.collect(&:id)}"
    }
  end

  def notification_messages
    {
      success: "Assignment export notification mailer was successfully delivered.",
      failure: "Assignment export notification mailer was not delivered."
    }
  end
end
