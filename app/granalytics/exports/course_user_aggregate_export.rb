class Exports::CourseUserAggregateExport
  include Granalytics::Export

  rows_by :users

  set_schema :username => :username,
             :role => :user_role,
             :total_pageviews => :pageviews,
             :total_logins => :logins,
             :total_predictor_events => :predictor_events,
             :total_predictor_sessions => :predictor_sessions

  def schema_records_for_role(role)
    self.schema_records records.select {|user| @roles[user.id] == role }
  end

  def initialize(loaded_data)
    @roles = loaded_data[:events].inject(Hash.new("")) do |hash, event|
      hash[event.user_id] = event.user_role
      hash
    end
    @user_predictor_event_counts = loaded_data[:predictor_events].inject(Hash.new(0)) do |hash, predictor_event|
      hash[predictor_event.user_id] += 1
      hash
    end
    @user_pageviews = loaded_data[:user_pageviews].inject(Hash.new(0)) do |hash, pageview|
      # pageview.pages raises an error w/ mongoid > 4.0.0
      hash[pageview.user_id] = pageview.raw_attributes["pages"]["_all"]["all_time"]
      hash
    end
    @user_logins = loaded_data[:user_logins].inject(Hash.new(0)) do |hash, login|
      hash[login.user_id] = login["all_time"]["count"]
      hash
    end
    @user_predictor_sessions = loaded_data[:user_predictor_pageviews].inject(Hash.new(0)) do |hash, predictor_pageview|
      hash[predictor_pageview.user_id] = predictor_pageview["all_time"]
      hash
    end
    super
  end

  def user_role(user, i)
    @roles[user.id]
  end

  def pageviews(user, i)
    @user_pageviews[user.id]
  end

  def logins(user, i)
    @user_logins[user.id]
  end

  def predictor_events(user, i)
    @user_predictor_event_counts[user.id]
  end

  def predictor_sessions(user, i)
    @user_predictor_sessions[user.id]
  end
end
