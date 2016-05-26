module ApplicationHelper
  include CustomNamedRoutes

  # current_user_is_student/professor/gsi/admin/staff?
  Role.all_with_staff.each do |role|
    define_method("current_user_is_#{role}?") do
      return unless current_user && current_course
      current_user.send("is_#{role}?", current_course)
    end
  end

  # Adding current user role to page class
  def body_class
    classes = []
    if logged_in?
      classes << "logged-in"
      classes << "staff" if current_user_is_staff?
      classes << current_user.role(current_course)
    else
      classes << "logged-out"
    end
    classes.join " "
  end

  # Return a title on a per-page basis.
  def title
    base_title = ""
    if @title.nil?
      base_title
    else
      "#{@title}"
    end
  end

  # Add class="active" to navigation item of current page
  def cp(path)
    "active" if current_page?(path)
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, "#", class: "add_fields", data: {
      id: id, fields: fields.gsub("\n", "")
      })
  end

  def json_for(target, options = {})
    options[:scope] ||= self
    options[:url_options] ||= url_options
    target.active_model_serializer.new(target, options).to_json
  end

  # Commas in numbers!
  def points(value)
    number_with_delimiter(value)
  end

  def multi_cache_key(category, *args)
    arguments = args.map {
      |arg| arg.respond_to?(:cache_key) ? arg.cache_key : arg
    }
    "#{category}/#{arguments.join("/")}"
  end
end
