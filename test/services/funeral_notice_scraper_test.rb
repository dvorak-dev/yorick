require 'test_helper'
require_relative '../support/stubbed_newspaper'

class FuneralNoticeScraperTest < ActiveSupport::TestCase
  include StubbedNewspaper

  def setup
    @date = Date.parse('2024-01-01')
    @url = 'https://funebres.eldia.com/edis/20240101/funebres2.htm'
    FuneralNotice.where(published_on: @date).delete_all
  end

  test 'should create notices from HTML' do
    with_page(two_notice_v2_html) do |requested_urls|
      assert_difference 'FuneralNotice.count', 2 do
        FuneralNoticeScraper.new(date: @date).call
      end

      assert_equal [@url, @url], requested_urls
    end

    notices = FuneralNotice.where(published_on: @date).order(:full_name)
    assert_equal 2, notices.count
    assert_equal 'JANE SMITH', notices.first.full_name
    assert_equal 'JOHN DOE', notices.last.full_name
    assert_equal @url, notices.last.source_link
  end

  test 'should raise error if notices already exist for date' do
    FuneralNotice.create!(
      full_name: 'EXISTING PERSON',
      content: 'Existing content',
      published_on: @date,
      source_link: @url
    )

    assert_raises ArgumentError do
      FuneralNoticeScraper.new(date: @date)
    end
  end

  test 'should raise error for date before start date' do
    early_date = Date.parse('2006-05-01')

    assert_raises ArgumentError do
      FuneralNoticeScraper.new(date: early_date)
    end
  end

  test 'should handle empty HTML gracefully' do
    with_page(empty_v2_html) do
      assert_no_difference 'FuneralNotice.count' do
        FuneralNoticeScraper.new(date: @date).call
      end
    end
  end

  test 'requests funebres2 for dates before the v3 cutoff' do
    date = Date.parse('2026-10-06')
    FuneralNotice.where(published_on: date).delete_all
    url = 'https://funebres.eldia.com/edis/20261006/funebres2.htm'

    with_page(two_notice_v2_html) do |requested_urls|
      assert_difference 'FuneralNotice.count', 2 do
        FuneralNoticeScraper.new(date: date).call
      end

      assert_equal [url, url], requested_urls
    end

    assert_equal url, FuneralNotice.find_by!(published_on: date, full_name: 'JOHN DOE').source_link
  end

  test 'parses funebres3 articles from the v3 cutoff' do
    date = Date.parse('2026-10-07')
    FuneralNotice.where(published_on: date).delete_all
    url = 'https://funebres.eldia.com/edis/20261007/funebres3.htm'

    with_page(two_notice_v3_html) do |requested_urls|
      assert_difference 'FuneralNotice.count', 2 do
        FuneralNoticeScraper.new(date: date).call
      end

      assert_equal [url, url], requested_urls
    end

    notices = FuneralNotice.where(published_on: date, full_name: 'JOHN DOE').order(:content)
    assert_equal 2, notices.count
    assert_equal '(Q.E.P.D.) First notice.', notices.first.content
    assert_equal '(Q.E.P.D.) Second notice.', notices.second.content
    assert_equal [url], notices.map(&:source_link).uniq
  end

  test 'ignores the names-only summary on a v3 page' do
    date = Date.parse('2026-10-07')
    FuneralNotice.where(published_on: date).delete_all

    with_page(summary_only_html) do
      assert_no_difference 'FuneralNotice.count' do
        FuneralNoticeScraper.new(date: date).call
      end
    end
  end
end
