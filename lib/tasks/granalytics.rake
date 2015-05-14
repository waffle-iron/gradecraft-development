namespace :granalytics do

  desc "Populate with events to simulate user activity"
  task :populate => :environment do

    if ENV['COURSE'] and Course.exists?(ENV['COURSE'])
      current_course = Course.find(ENV['COURSE'])
    else
      raise("No course provided. Please add COURSE=ID to the rake task")
    end

    semester_duration = current_course.end_date - current_course.start_date

    user_count = User.count
    events = [].tap do |e|
      e << :login
      20.times do
        e << :pageview
      end
      10.times do
        e << :predictor
      end
    end
    random_score = Rubystats::NormalDistribution.new

    begin
      puts "Sending lots of events, stop by pressing ^c"
      loop do
        user = User.offset(rand(user_count)).limit(1).first
        event = events.sample
        if user.is_student?(current_course)
          created_at = current_course.start_date + Random.rand(semester_duration)
          data =  case event
                  when :pageview
                    pages = %w(/ /dashboard /users/predictor)
                    {:page => pages.sample}
                  when :login
                    # Set the last login at up to 100 hours prior
                    last_login_at = created_at - Random.rand(3600)
                    last_login_at = last_login_at > current_course.start_date ? last_login_at : current_course.start_date
                    {:last_login_at => last_login_at}
                  when :predictor
                    assignment = current_course.assignments.sample
                    if assignment
                      possible = assignment.point_total_for_student(user)
                      # Our normal distribution should center its mean around
                      # half of the possible score.
                      # To make sure we get 99.7% of our scores within the range,
                      # we'll multiple by half our range divided by 3 standard deviations.
                      score = (random_score.rng * (possible/2)/3) + possible/2
                      score = [0,score].max
                      score = [possible,score].min
                      {:assignment_id => assignment.id, :score => score.to_i, :possible => possible}
                    else
                      false
                    end
                  end

          attributes = {course_id: current_course.id, user_id: user.id, user_role: user.role(current_course), created_at: created_at}
          Resque.enqueue(EventLogger, event, attributes.merge(data)) if data
          #EventLogger.perform_async(event, attributes.merge(data)) if data
          puts "#{event}: #{attributes.merge(data)}" if data
          sleep(rand)
        end
      end
    rescue Interrupt => e
      puts ""
      puts "Stopping."
    end
  end

  namespace :export do
    namespace :courses do
      desc "Export all course analytics data as JSON"
      task :raw => [:environment] do
        export_dir = ENV['EXPORT_DIR']
        course_ids.each do |id|
          puts "Exporting for course: #{id}"

          puts "Generating JSON export files"
          %w(analytics_events course_events course_role_events course_predictions course_user_events course_pageviews course_user_pageviews course_user_page_pageviews course_pageview_by_times course_page_pageviews course_role_pageviews course_role_page_pageviews course_logins course_role_logins course_user_logins).each do |aggregate|
            `mongoexport --db grade_craft_development --collection #{aggregate} --query '{"course_id": #{id}}' --out #{File.join(export_dir, id.to_s, "json", "#{aggregate}.json")}`
          end
        end

        puts "Done!"
      end

      desc "Export filtered course analytics data as CSV"
      task :csv => [:environment] do
        export_dir = ENV['EXPORT_DIR'] || raise("No export directory provided. Prepend \"EXPORT_DIR=/path/to/exports\" to rake command.")
        course_ids.each do |id|
          puts "Exporting for course: #{id}"

          # NOTE: These could be refactored into a reusable method to generate the mongoexport,
          # but it's easier to read and see what commands they're running by just having them typed out.
          puts "Generating CSV reports"
          # course user pageviews
          `mongoexport --db grade_craft_development --fields user_id,pages._all.all_time --collection course_user_pageviews --query '{"course_id": #{id}}' --out #{File.join(export_dir, id.to_s, "csv", "course_user_pageviews_total.csv")} --csv`
          # course user logins
          `mongoexport --db grade_craft_development --fields user_id,all_time.count --collection course_user_logins --query '{"course_id": #{id}}' --out #{File.join(export_dir, id.to_s, "csv", "course_user_logins_total.csv")} --csv`
          # course user predictor events
          `mongoexport --db grade_craft_development --fields user_id,events.predictor.all_time --collection course_user_events --query '{"course_id": #{id}}' --out #{File.join(export_dir, id.to_s, "csv", "course_user_predictor_events_total.csv")} --csv`
          # course user predictor pageviews
          `mongoexport --db grade_craft_development --fields "user_id,all_time" --collection course_user_page_pageviews --query '{"course_id": #{id}, "page": "/dashboard#predictor"}' --out #{File.join(export_dir, id.to_s, "csv", "course_user_predictor_pageviews_total.csv")} --csv`
          # user predictor events with role, assignment, prediction score, and datetime
          `mongoexport --db grade_craft_development --fields user_id,user_role,assignment_id,score,possible,created_at --collection analytics_events --query '{"course_id": #{id}, "event_type": "predictor"}' --out #{File.join(export_dir, id.to_s, "csv", "course_user_predictor_events.csv")} --csv`
          # user event with page, event, and datetime
          `mongoexport --db grade_craft_development --fields user_id,user_role,event_type,page,created_at --collection analytics_events --query '{"course_id": #{id}}' --out #{File.join(export_dir, id.to_s, "csv", "course_user_events.csv")} --csv`
        end

        puts "Done!"
      end

      desc "Export analyzed course analytics data as CSV"
      task :csv_analyzed => [:environment] do
        export_dir = ENV['EXPORT_DIR'] || raise("No export directory provided. Prepend \"EXPORT_DIR=/path/to/exports\" to rake command.")
        selected_course_ids = ENV['COURSES'].try(:split, ',').try(:map, &:to_i)
        export_course_ids = selected_course_ids.present? ? (selected_course_ids & course_ids) : course_ids
        elapsed = Benchmark.realtime do
          export_course_ids.each do |id|
            course_export_dir = File.join(export_dir, id.to_s, "csv_analyzed")

            puts "Exporting for course: #{id}"
            puts "Gathering data (this may take a minute)..."

            %w"student professor gsi admin total".each do |role|
              role_subdir = File.join(course_export_dir,role.pluralize)

              events = Granalytics::Event.where(:course_id => id)
              predictor_events = Granalytics::Event.where(:course_id => id, :event_type => "predictor")
              user_pageviews = CourseUserPageview.data(:all_time, nil, {:course_id => id}, {:page => "_all"})
              user_predictor_pageviews = CourseUserPagePageview.data(:all_time, nil, {:course_id => id, :page => "/dashboard#predictor"})
              user_logins = CourseUserLogin.data(:all_time, nil, {:course_id => id})

              user_ids = events.collect(&:user_id).compact.uniq
              assignment_ids = events.select { |event| event.respond_to? :assignment_id }.collect(&:assignment_id).compact.uniq

              users = User.where(:id => user_ids).select(:id, :username)
              assignments = Assignment.where(:id => assignment_ids).select(:id, :name)

              data = {
                :events => events,
                :predictor_events => predictor_events,
                :user_pageviews => user_pageviews[:results],
                :user_predictor_pageviews => user_predictor_pageviews[:results],
                :user_logins => user_logins[:results],
                :users => users,
                :assignments => assignments
              }

              Granalytics.configuration.exports[:course].each do |export|
                puts "Generating report: #{export}"
                exp = export.new(data)
                if role == "total"
                  exp.generate_csv(role_subdir)
                else
                  exp.generate_csv(role_subdir, nil, exp.schema_records_for_role(role))
                end
              end
            end
          end
        end
        puts "Done! Total elapsed time: #{elapsed} seconds"
      end

      def course_ids
        @course_ids ||= Granalytics::Event.distinct(:course_id)
      end
    end
  end
end
