module FuneralNoticesHelper
  def format_published_date(date)
    # Spanish month names
    months = {
      1 => 'enero', 2 => 'febrero', 3 => 'marzo', 4 => 'abril',
      5 => 'mayo', 6 => 'junio', 7 => 'julio', 8 => 'agosto',
      9 => 'septiembre', 10 => 'octubre', 11 => 'noviembre', 12 => 'diciembre'
    }

    day = date.day
    month = months[date.month]
    year = date.year

    "Publicado el #{day} de #{month} de #{year}"
  end

  def search_active?
    %i[full_name content year_from year_to].any? { |key| params[key].present? }
  end

  def filters_applied?
    search_active? || params[:order].in?(%w[asc desc])
  end

  def active_filter_summary
    parts = [
      labeled_filter('Nombre', :full_name), labeled_filter('Texto', :content),
      year_filter_summary, sort_filter_summary
    ].compact
    parts.join(' · ').presence || 'Sin filtros'
  end

  def sort_link(label, order)
    active = sort_active?(order)
    options = { class: sort_link_class(active) }
    options[:aria] = { current: 'true' } if active
    link_to(label, funeral_notices_path(sort_query(order)), options)
  end

  private

  def labeled_filter(label, key)
    "#{label}: #{params[key]}" if params[key].present?
  end

  def year_filter_summary
    return if params[:year_from].blank? && params[:year_to].blank?

    "Publicado: #{params[:year_from].presence || '…'}–#{params[:year_to].presence || '…'}"
  end

  def sort_filter_summary
    "Orden: #{active_sort_label}"
  end

  def active_sort_label
    return 'Más antiguos' if params[:order] == 'asc'
    return 'Relevancia' if search_active? && params[:order] != 'desc'

    'Más recientes'
  end

  def sort_active?(order)
    chosen = params[:order] if params[:order].in?(%w[asc desc])
    return chosen.nil? if order.nil?
    return true if chosen == order

    order == 'desc' && chosen.nil? && !search_active?
  end

  def sort_query(order)
    query = request.query_parameters.except('page', 'order')
    order.present? ? query.merge('order' => order) : query
  end

  def sort_link_class(active)
    base = 'px-3 py-2 rounded'
    return "#{base} bg-[#0f172a] text-white font-semibold" if active

    "#{base} bg-gray-200 text-gray-700 hover:bg-gray-300"
  end
end
