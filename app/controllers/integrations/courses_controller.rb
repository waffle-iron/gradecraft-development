class Integrations::CoursesController < ApplicationController
  include OAuthProvider

  oauth_provider_param :integration_id

  before_action :ensure_staff?
  before_action do |controller|
    controller.redirect_path(integration_courses_path(params[:integration_id]))
  end
  before_action :require_authorization

  def index
    @course = current_course
    authorize! :read, @course

    @provider_name = params[:integration_id]
    @courses = syllabus(@provider_name).courses do
      redirect_to integrations_path,
        alert: "There was an issue trying to retrieve the courses from #{@provider_name.capitalize}." and return
    end
  end

  def create
    course = current_course
    authorize! :update, course

    provider_name = params[:integration_id]
    linked_course = LinkedCourse.find_or_initialize_by course_id: course.id,
      provider: provider_name
    linked_course.provider_resource_id = params[:id]
    linked_course.last_linked_at = DateTime.now
    linked_course.save

    redirect_to integrations_path, notice: "The #{provider_name.capitalize} course has been linked to #{course.name}"
  end

  def destroy
    course = current_course
    authorize! :update, course

    provider_name = params[:integration_id]

    LinkedCourse.where(provider: provider_name,
                       course_id: course.id,
                       provider_resource_id: params[:id]).destroy_all

    redirect_to integrations_path, notice: "The #{provider_name.capitalize} course has been unlinked from #{course.name}"
  end

  private

  def syllabus(provider)
    @syllabus ||= ActiveLMS::Syllabus.new \
      provider,
      authorization(provider).access_token
  end
end
