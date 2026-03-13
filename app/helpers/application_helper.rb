module ApplicationHelper
  # Returns "active" CSS class when the current request path matches the given path.
  def active_link_class(path)
    current_page?(path) ? "active" : ""
  end

  def render_markdown(text)
    return "" if text.blank?

    html = ERB::Util.html_escape(text)

    # Bold: **text**
    html = html.gsub(/\*\*(.+?)\*\*/m, '<strong>\1</strong>')

    # Italic: *text*
    html = html.gsub(/\*(.+?)\*/m, '<em>\1</em>')

    # Inline code: `code`
    html = html.gsub(/`(.+?)`/, '<code>\1</code>')

    # Unordered lists: lines starting with - or *
    html = html.gsub(/^[\-\*] (.+)$/, '<li>\1</li>')

    # Numbered lists: lines starting with 1. 2. etc
    html = html.gsub(/^\d+\. (.+)$/, '<li>\1</li>')

    # Wrap consecutive <li> in <ul>
    html = html.gsub(/((?:<li>.*<\/li>\n?)+)/) do |match|
      "<ul>#{match}</ul>"
    end

    # Headers
    html = html.gsub(/^### (.+)$/, '<h4>\1</h4>')
    html = html.gsub(/^## (.+)$/, '<h3>\1</h3>')

    # Line breaks
    html = html.gsub("\n", "<br>")

    # Clean up extra br in lists
    html = html.gsub("</li><br>", "</li>")
    html = html.gsub("</ul><br>", "</ul>")
    html = html.gsub("</ol><br>", "</ol>")

    html.html_safe
  end
end
