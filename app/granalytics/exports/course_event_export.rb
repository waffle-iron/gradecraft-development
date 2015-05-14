class Exports::CourseEventExport
  include Granalytics::Export

  rows_by :events

  set_schema  :username => :username,
              :role => :user_role,
              :page => :page,
              :action => :page_name,
              :date_time => lambda { |event| event.created_at.to_formatted_s(:db) }

  def schema_records_for_role(role)
    self.schema_records records.select {|event| event.user_role == role }
  end

  def initialize(loaded_data)
    @usernames = loaded_data[:users].inject({}) do |hash, user|
      hash[user.id] = user.username
      hash
    end
    super
  end

  def username(event, index)
    @usernames[event.user_id] || "[user id: #{event.user_id}]"
  end

  def page(event, index)
    event.try(:page) || "[n/a]"
  end

  def page_name(event, index)
    nil
  end
end
