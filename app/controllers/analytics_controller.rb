class AnalyticsController < ApplicationController
  before_filter :ensure_staff?
  before_filter :set_granularity_and_range

  def index
    @title = "User Analytics"
  end

  def students
    @title = "#{term_for :student} Analytics"
  end

  def staff
    @title = "#{term_for :team_leader} Analytics"
  end

  def all_events
    data = CourseEvent.data(@granularity, @range,
      { course_id: current_course.id }, { event_type: "_all" })

    render json: MultiJson.dump(data)
  end

  def role_events
    data = CourseRoleEvent.data(@granularity, @range, {
      course_id: current_course.id, role_group: params[:role_group]
      }, { event_type: "_all" })

    render json: MultiJson.dump(data)
  end

  def assignment_events
    assignments = Hash[current_course.assignments.select([:id, :name]).collect{
      |h| [h.id, h.name]
      }]
    data = AssignmentEvent.data(@granularity, @range,
      {assignment_id: assignments.keys},
      {event_type: "_all"})

    data.decorate! {
      |result| result[:name] = assignments[result.assignment_id]
    }

    render json: MultiJson.dump(data)
  end

  def login_frequencies
    data = CourseLogin.data(@granularity, @range, {
      course_id: current_course.id
      })

    data[:lookup_keys] = ["{{t}}.average"]

    data.decorate! do |result|
      result[:name] = "Average #{data[:granularity]} login frequency"
      # Get frequency
      result[data[:granularity]].each do |key, values|
        result[data[:granularity]][key][:average] =
          (values["total"] / values["count"]).round(2)
      end
    end

    render json: MultiJson.dump(data)
  end

  def role_login_frequencies
    data = CourseRoleLogin.data(@granularity, @range,
      {course_id: current_course.id, role_group: params[:role_group]})

    data[:lookup_keys] = ["{{t}}.average"]

    data.decorate! do |result|
      result[:name] = "Average #{data[:granularity]} login frequency"
      # Get frequency
      result[data[:granularity]].each do |key, values|
        result[data[:granularity]][key][:average] = (values["total"] /
          values["count"]).round(2)
      end
    end

    render json: MultiJson.dump(data)
  end

  def login_events
    data = CourseLogin.data(@granularity, @range, {
      course_id: current_course.id
      })

    # Only graph counts
    data[:lookup_keys] = ["{{t}}.count"]

    render json: MultiJson.dump(data)
  end

  def login_role_events
    data = CourseRoleLogin.data(@granularity, @range,
      {course_id: current_course.id, role_group: params[:role_group]})

    # Only graph counts
    data[:lookup_keys] = ["{{t}}.count"]

    render json: MultiJson.dump(data)
  end

  def all_pageview_events
    data = CoursePageview.data(@granularity, @range,
      {course_id: current_course.id}, {page: "_all"})

    render json: MultiJson.dump(data)
  end

  def all_role_pageview_events
    data = CourseRolePageview.data(@granularity, @range,
      {course_id: current_course.id, role_group: params[:role_group]},
      {page: "_all"})

    render json: MultiJson.dump(data)
  end

  def all_user_pageview_events
    user = current_course.students.find(params[:user_id])
    data = CourseUserPageview.data(@granularity, @range,
      {course_id: current_course.id, user_id: user.id},
      {page: "_all"})

    render json: MultiJson.dump(data)
  end

  def pageview_events
    data = CoursePagePageview.data(@granularity, @range,
      {course_id: current_course.id})
    data.decorate! { |result| result[:name] = result.page }

    render json: MultiJson.dump(data)
  end

  def role_pageview_events
    data = CourseRolePagePageview.data(@granularity, @range,
      {course_id: current_course.id, role_group: params[:role_group]})
    data.decorate! { |result| result[:name] = result.page }

    render json: MultiJson.dump(data)
  end

  def user_pageview_events
    user = current_course.students.find(params[:user_id])
    data = CourseUserPagePageview.data(@granularity, @range,
      {course_id: current_course.id, user_id: user.id})
    data.decorate! { |result| result[:name] = result.page }

    render json: MultiJson.dump(data)
  end

  def prediction_averages
    data = CoursePrediction.data(@granularity, @range,
      {course_id: current_course.id})

    data[:lookup_keys] = ["{{t}}.average"]
    data.decorate! do |result|
      result[data[:granularity]].each do |key, values|
        result[data[:granularity]][key][:average] =
          (values["total"] / values["count"] * 100).to_i
      end
    end

    render json: MultiJson.dump(data)
  end

  def assignment_prediction_averages
    assignments = Hash[current_course.assignments.select([:id, :name]).collect{
      |h| [h.id, h.name]
      }]
    data = AssignmentPrediction.data(@granularity, @range, {
      assignment_id: assignments.keys
      })

    data[:lookup_keys] = ["{{t}}.count", "{{t}}.total"]
    data.decorate! do |result|
      result[:name] = assignments[result.assignment_id]
    end

    render json: MultiJson.dump(data)
  end

  # TODO: fix this
  def export
    respond_to do |format|
      format.zip do
        export_dir = Dir.mktmpdir
        export_zip "#{ current_course.courseno }_anayltics_export_#{ Time.now.strftime('%Y-%m-%d') }", export_dir do

          (Role.all + ["total"]).each do |role|
            role_subdir = File.join(export_dir,role.pluralize)
            id = current_course.id
            events = Analytics::Event.where(course_id: id)
            predictor_events =
              Analytics::Event.where(course_id: id, event_type: "predictor")
            user_pageviews = CourseUserPageview.data(:all_time, nil, {
              course_id: id
              },
              { page: "_all" })
            user_predictor_pageviews =
              CourseUserPagePageview.data(:all_time, nil, {
              course_id: id, page: "/dashboard#predictor"
              })
            user_logins = CourseUserLogin.data(:all_time, nil, {
              course_id: id
              })

            user_ids = events.collect(&:user_id).compact.uniq
            assignment_ids = events.select {
              |event| event.respond_to? :assignment_id
            }.collect(&:assignment_id).compact.uniq
            users = User.where(id: user_ids).select(:id, :username)
            assignments =
              Assignment.where(id: assignment_ids).select(:id, :name)

            data = {
              events: events,
              predictor_events: predictor_events,
              user_pageviews: user_pageviews[:results],
              user_predictor_pageviews: user_predictor_pageviews[:results],
              user_logins: user_logins[:results],
              users: users,
              assignments: assignments
            }
            Analytics.configuration.exports[:course].each do |export|
              exp = export.new(data)
              if role == "total"
                exp.generate_csv(role_subdir)
              else
                exp.generate_csv(role_subdir,
                nil, exp.schema_records_for_role(role))
              end
            end
          end # each role
        end
      end
    end
  end

  private

  def set_granularity_and_range
    @granularity = :daily

    if current_course.start_date && current_course.end_date
      @range = (current_course.start_date..current_course.end_date)
    else
      @range = :past_year
    end
  end
end
