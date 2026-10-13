require 'test_helper'
require_relative '../support/stubbed_newspaper'

class FuneralNoticeRecoveryScraperTest < ActiveSupport::TestCase
  include StubbedNewspaper

  def setup
    @date = Date.parse('2024-01-01')
    @url = 'https://funebres.eldia.com/edis/20240101/funebres2.htm'
    FuneralNotice.where(published_on: @date).delete_all
  end

  test 'should create missing notices' do
    with_page(one_notice_v2_html) do |requested_urls|
      assert_difference 'FuneralNotice.count', 1 do
        FuneralNoticeRecoveryScraper.new(date: @date).call
      end

      assert_equal [@url, @url], requested_urls
    end

    notice = FuneralNotice.find_by!(published_on: @date, full_name: 'JOHN DOE')
    assert_equal '(Q.E.P.D.) Falleció el 30/06/2025.- Su esposa: Jane Doe; sus hijos: John Jr. y Jane Jr. ' \
                 'participan su fallecimiento.', notice.content
    assert_equal @date, notice.published_on
    assert_equal @url, notice.source_link
  end

  test 'should skip existing notices' do
    FuneralNotice.create!(
      full_name: 'JOHN DOE',
      content: '(Q.E.P.D.) Falleció el 30/06/2025.- Su esposa: Jane Doe; sus hijos: John Jr. y Jane Jr. ' \
               'participan su fallecimiento.',
      published_on: @date,
      source_link: @url
    )

    with_page(one_notice_v2_html) do
      assert_no_difference 'FuneralNotice.count' do
        FuneralNoticeRecoveryScraper.new(date: @date).call
      end
    end
  end

  test 'parses missing funebres3 articles from the v3 cutoff' do
    date = Date.parse('2026-10-07')
    FuneralNotice.where(published_on: date).delete_all
    url = 'https://funebres.eldia.com/edis/20261007/funebres3.htm'

    with_page(two_notice_v3_html) do |requested_urls|
      assert_difference 'FuneralNotice.count', 2 do
        FuneralNoticeRecoveryScraper.new(date: date).call
      end

      assert_equal [url, url], requested_urls
    end

    notices = FuneralNotice.where(published_on: date).order(:content)
    assert_equal ['(Q.E.P.D.) First notice.', '(Q.E.P.D.) Second notice.'], notices.map(&:content)
    assert_equal [url], notices.map(&:source_link).uniq
  end

  test 'skips an existing notice on a v3 page' do
    date = Date.parse('2026-10-07')
    FuneralNotice.where(published_on: date).delete_all
    url = 'https://funebres.eldia.com/edis/20261007/funebres3.htm'
    FuneralNotice.create!(
      full_name: 'JOHN DOE',
      content: '(Q.E.P.D.) First notice.',
      published_on: date,
      source_link: url
    )

    with_page(two_notice_v3_html) do
      assert_difference 'FuneralNotice.count', 1 do
        FuneralNoticeRecoveryScraper.new(date: date).call
      end
    end

    created = FuneralNotice.find_by!(published_on: date, content: '(Q.E.P.D.) Second notice.')
    assert_equal 'JOHN DOE', created.full_name
    assert_equal url, created.source_link
  end
end
