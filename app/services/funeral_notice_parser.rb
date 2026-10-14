class FuneralNoticeParser
  V3_START = Date.new(2026, 10, 7)
  BASE_URL = 'https://funebres.eldia.com/edis/%<date>s/%<file>s'.freeze

  def self.for(date)
    date >= V3_START ? V3.new : V2.new
  end

  def url_for(date)
    format(BASE_URL, date: date.strftime('%Y%m%d'), file: filename)
  end

  class V2 < FuneralNoticeParser
    def extract(doc)
      doc.css('div.grid_10.funebres li.c').filter_map { |notice| extract_notice(notice) }
    end

    private

    def filename
      'funebres2.htm'
    end

    def extract_notice(notice)
      span = notice.at('span')
      content = span&.text&.strip
      span&.remove
      full_name = notice.text.strip
      return if full_name.blank? || content.blank?

      { full_name:, content: }
    end
  end

  class V3 < FuneralNoticeParser
    def extract(doc)
      doc.css('article.notice').filter_map { |notice| extract_notice(notice) }
    end

    private

    def filename
      'funebres3.htm'
    end

    def extract_notice(notice)
      heading = notice.at('h3')
      heading&.css('.rs')&.remove
      full_name = heading&.text&.strip
      content = notice.at('p')&.text&.strip
      return if full_name.blank? || content.blank?

      { full_name:, content: }
    end
  end
end
