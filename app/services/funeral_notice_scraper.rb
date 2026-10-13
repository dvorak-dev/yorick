require 'open-uri'

class FuneralNoticeScraper
  START_DATE = Date.parse('2006-05-02')

  def initialize(date:)
    @date = date.is_a?(String) ? Date.parse(date) : date
    @parser = FuneralNoticeParser.for(@date)
    validate_date!
  end

  def call
    url = @parser.url_for(@date)

    unless url_available?(url)
      Rails.logger.info "🔍 Newspaper not found for #{@date} (URL: #{url})"
      return
    end

    Rails.logger.debug { "📅 Scraping #{@date} from #{url}" }

    begin
      doc = Nokogiri::HTML(read_page(url))
      save_notices(doc, url)
    rescue StandardError => e
      Rails.logger.warn "⚠️ Error scraping #{url}: #{e.message}"
    end
  end

  private

  def validate_date!
    raise ArgumentError, "Date must be on or after #{START_DATE}" if @date < START_DATE

    return unless FuneralNotice.exists?(published_on: @date)

    raise ArgumentError, "Funeral notices already exist for #{@date}"
  end

  def url_available?(url)
    # rubocop:disable Security/Open
    URI.open(url) { true }
    # rubocop:enable Security/Open
  rescue OpenURI::HTTPError => e
    Rails.logger.info "URL not found: #{url} (#{e.message})"
    false
  end

  def read_page(url)
    # rubocop:disable Security/Open
    URI.open(url).read
    # rubocop:enable Security/Open
  end

  def save_notices(doc, url)
    @parser.extract(doc).each do |notice|
      Rails.logger.debug { "Found notice: #{notice[:full_name]} - #{notice[:content][0..50]}..." }

      FuneralNotice.find_or_create_by!(
        full_name: notice[:full_name],
        content: notice[:content],
        published_on: @date,
        source_link: url
      )
    end
  end
end
