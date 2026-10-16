class FuneralNoticesController < ApplicationController
  def index
    @pagy, @funeral_notices = if params[:full_name].present? || params[:content].present?
                                search_funeral_notices
                              else
                                pagy(:offset, FuneralNotice.order(published_on: :desc, full_name: :asc))
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

  def build_full_name_query(query)
    {
      multi_match: {
        query: query,
        fields: ['full_name^3', 'full_name._2gram^2', 'full_name._3gram'],
        type: 'best_fields',
        fuzziness: 'AUTO',
        operator: 'and',
        minimum_should_match: '75%',
        boost: 2.0,
        tie_breaker: 0.3,
        max_expansions: 10
      }
    }
  end

  def build_content_query(query)
    {
      multi_match: {
        query: query,
        fields: ['content^2', 'content._2gram', 'content._3gram'],
        type: 'best_fields',
        fuzziness: 'AUTO',
        operator: 'and',
        minimum_should_match: '50%',
        boost: 1.0,
        tie_breaker: 0.3,
        max_expansions: 10
      }
    }
  end

  def build_search_query(params)
    return {} if params.blank?

    queries = []
    queries << build_full_name_query(params[:full_name]) if params[:full_name].present?
    queries << build_content_query(params[:content]) if params[:content].present?

    return {} if queries.empty?

    {
      bool: {
        should: queries,
        minimum_should_match: 1
      }
    }
  end

  def search_funeral_notices
    search_query = build_search_query(search_params)
    return pagy(:offset, FuneralNotice.order(published_on: :desc, full_name: :asc)) if search_query.empty?

    # Get all matching results from Elasticsearch (up to 500)
    results = FuneralNoticesIndex.query(search_query).limit(500).load
    ids = results.map(&:id)
    notices = FuneralNotice.where(id: ids).index_by(&:id)
    ordered_notices = ids.filter_map { |id| notices[id.to_i] }

    # Sort by published_on desc, full_name asc
    sorted_notices = sort_notices_by_date_and_name(ordered_notices)
    pagy(:offset, sorted_notices)
  end

  def sort_notices_by_date_and_name(notices)
    notices.sort_by { |notice| [-notice.published_on.to_time.to_i, notice.full_name.downcase] }
  end

  def search_params
    params.except(:commit).permit(:full_name, :content)
  end
end
