class FuneralNoticesController < ApplicationController
  def index
    @pagy, @funeral_notices = if params[:full_name].present? || params[:content].present?
                                search_funeral_notices
                              else
                                default_notice_page
                              end

    # Set cache headers for index page
    fresh_when(@funeral_notices.first, etag: [@funeral_notices, @pagy.page, search_params])
  end

  # rubocop:disable Metrics/AbcSize
  def show
    date_str = params[:date]
    name_hash = params[:name_hash]

    raise ActiveRecord::RecordNotFound if date_str.blank? || name_hash.blank?

    date = Date.parse(date_str)

    # Parse name-hash_id format (e.g., "mariana-santos-f6524f")
    raise ActiveRecord::RecordNotFound unless name_hash.include?('-')

    parts = name_hash.split('-')
    hash_id = parts.last # Last part is the hash

    @funeral_notice = FuneralNotice.find_by!(
      published_on: date,
      hash_id: hash_id
    )

    # Redirect if the name-hash doesn't match the canonical route
    expected_name_hash = "#{@funeral_notice.full_name.parameterize}-#{@funeral_notice.hash_id}"
    unless name_hash.downcase == expected_name_hash.downcase
      redirect_to funeral_notice_path(@funeral_notice.route_params), status: :moved_permanently and return
    end

    fresh_when(@funeral_notice, etag: @funeral_notice)
    Rails.logger.info "Found funeral notice: #{@funeral_notice.full_name} (ID: #{@funeral_notice.id})"
  end
  # rubocop:enable Metrics/AbcSize

  private

  def default_notice_page
    pagy(:offset, FuneralNotice.order(published_on: :desc, full_name: :asc))
  end

  def build_search_query(search)
    queries = []
    queries << FuneralNoticeSearch.field_query('full_name', search[:full_name]) if search[:full_name].present?
    queries << FuneralNoticeSearch.field_query('content', search[:content]) if search[:content].present?
    queries.compact!
    return {} if queries.empty?

    { bool: { should: queries, minimum_should_match: 1 } }
  end

  def search_funeral_notices
    search_query = build_search_query(search_params)
    return default_notice_page if search_query.empty?

    page = current_search_page
    request = search_request(search_query, page)
    pagy = Pagy::Offset.new(count: request.count, page: page, limit: Pagy::OPTIONS[:limit])
    [pagy, notices_in_hit_order(request)]
  end

  def current_search_page
    [params[:page].to_i, 1].max
  end

  def search_request(search_query, page)
    limit = Pagy::OPTIONS[:limit]
    FuneralNoticesIndex.query(search_query)
      .order({ _score: { order: :desc } }, { published_on: { order: :desc } })
      .limit(limit)
      .offset((page - 1) * limit)
  end

  def notices_in_hit_order(request)
    ids = request.to_a.map { |hit| hit.id.to_i }
    notices = FuneralNotice.where(id: ids).index_by(&:id)
    ids.filter_map { |id| notices[id] }
  end

  def search_params
    params.except(:commit).permit(:full_name, :content)
  end
end
