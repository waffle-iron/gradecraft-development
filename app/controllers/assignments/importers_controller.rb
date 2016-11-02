require_relative "../../services/imports_lms_assignments"

class Assignments::ImportersController < ApplicationController
  include OAuthProvider

  oauth_provider_param :importer_provider_id

  before_action :ensure_staff?
  before_action except: :index do |controller|
    controller.redirect_path assignments_importers_path
  end
  before_action :require_authorization, except: :index

  # GET /assignments/importers
  def index
  end

  # GET /assignments/importers/:importer_provider_id/courses/:id/assignments
  def assignments
    @provider_name = params[:importer_provider_id]
    @course = syllabus.course(params[:id]) do
      redirect_to assignment_importers_path,
          alert: "There was an issue trying to retrieve the course from #{@provider_name.capitalize}." and return
    end
    @assignments = syllabus.assignments(params[:id]) do
      redirect_to assignment_importers_path,
          alert: "There was an issue trying to retrieve the assignments from #{@provider_name.capitalize}." and return
    end
    @assignment_types = current_course.assignment_types.ordered
  end

  # POST /assignments/importers/:importer_provider_id/courses/:id/assignments
  def assignments_import
    @provider_name = params[:importer_provider_id]
    @course_id = params[:id]

    @result = Services::ImportsLMSAssignments.import @provider_name,
      authorization(@provider_name).access_token, @course_id, params[:assignment_ids],
      current_course, params[:assignment_type_id]

    if @result.success?
      render :assignments_import_results
    else
      @course = syllabus.course(@course_id) do
        redirect_to assignment_importers_path,
          alert: "There was an issue trying to retrieve the course from #{@provider_name.capitalize}." and return
      end
      @assignments = syllabus.assignments(@course_id) do
        redirect_to assignment_importers_path,
          alert: "There was an issue trying to retrieve the assignments from #{@provider_name.capitalize}." and return
      end
      @assignment_types = current_course.assignment_types.ordered

      render :assignments, alert: @result.message
    end
  end

  # POST /assignments/importers/:importer_provider_id/assignments/:id/refresh
  def refresh_assignment
    provider_name = params[:importer_provider_id]
    assignment = Assignment.find(params[:id])

    result = Services::ImportsLMSAssignments.refresh provider_name,
      authorization(provider_name).access_token, assignment

    if result.success?
      flash[:notice] = "You have successfully updated #{assignment.name} from #{provider_name.capitalize}"
    else
      flash[:alert] = result.message
    end

    redirect_to assignment_path(assignment)
  end

  # POST /assignments/importers/:importer_provider_id/assignments/:id/update
  def update_assignment
    provider_name = params[:importer_provider_id]
    assignment = Assignment.find(params[:id])

    result = Services::ImportsLMSAssignments.update provider_name,
      authorization(provider_name).access_token, assignment

    if result.success?
      flash[:notice] = "You have successfully updated #{assignment.name} on #{provider_name.capitalize}"
    else
      flash[:alert] = result.message
    end

    redirect_to assignment_path(assignment)
  end

  private

  def syllabus
    @syllabus ||= ActiveLMS::Syllabus.new \
      @provider_name,
      authorization(@provider_name).access_token
  end
end
