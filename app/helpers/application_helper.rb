module ApplicationHelper
  def highlight_search_terms(text, query)
    return text if text.blank? || query.blank?

    pattern = FuneralNoticeSearch.highlight_pattern(query)
    return text if pattern.nil?

    highlighted = text.gsub(pattern) { |match| "<mark>#{match}</mark>" }
    # rubocop:disable Rails/OutputSafety
    highlighted.html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def highlight_fields(notice, full_name_query, content_query)
    highlighted_full_name = highlight_search_terms(notice.full_name, full_name_query)
    highlighted_content = highlight_search_terms(notice.content, content_query)
    { full_name: highlighted_full_name, content: highlighted_content }
  end
end
