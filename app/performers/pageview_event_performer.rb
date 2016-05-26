# @mz TODO: add specs
class PageviewEventPerformer < ResqueJob::Performer
  # perform() attributes assigned to @attrs in the ResqueJob::Base class
  def do_the_work
    require_success(messages) do
      Analytics::Event.create pageview_event_attrs
    end
  end

  private

  def pageview_event_attrs
    { event_type: "pageview" }.merge @attrs[:data]
  end

  def messages
    {
      success: "Pageview analytics event was successfully created.",
      failure: "Pageview analytics event failed to create."
    }
  end
end
