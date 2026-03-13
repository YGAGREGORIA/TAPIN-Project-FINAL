module ApplicationHelper
  # Returns "active" CSS class when the current request path matches the given path.
  def active_link_class(path)
    current_page?(path) ? "active" : ""
  end
end
