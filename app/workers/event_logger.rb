class EventLogger
  @queue= :eventlogger

  def self.perform(event_type, data={})
  	p "Starting EventLogger"
  	begin
    	attributes = {event_type: event_type, created_at: Time.now}
    	Granalytics::Event.create(attributes.merge(data))
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
	  end
  end
end
