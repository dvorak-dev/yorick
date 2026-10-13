require 'open-uri'

class FuneralNoticeRecoveryScraper
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

    Rails.logger.debug { "📅 Recovery scraping #{@date} from #{url}" }

    begin
      doc = Nokogiri::HTML(read_page(url))
      recover_notices(doc, url)
    rescue StandardError => e
      Rails.logger.warn "⚠️ Error recovery scraping #{url}: #{e.message}"
    end
  end

  private

  def validate_date!
    return unless @date < START_DATE

    raise ArgumentError, "Date must be on or after #{START_DATE}"
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

  def recover_notices(doc, url)
    @parser.extract(doc).each do |notice|
      next if duplicate?(notice)

      Rails.logger.debug { "✅ Recovered missing notice: #{notice[:full_name]} - #{notice[:content][0..50]}..." }

      FuneralNotice.create!(
        full_name: notice[:full_name],
        content: notice[:content],
        published_on: @date,
        source_link: url
      )
    end
  end

  def duplicate?(notice)
    return false unless FuneralNotice.exists?(published_on: @date, content: notice[:content])

    Rails.logger.debug { "⏩ Skipping duplicate notice: #{notice[:full_name]} - #{notice[:content][0..50]}..." }
    true
  end
end
