require 'test_helper'

module FuneralNoticeSearchTestSupport
  def with_page_limit(limit)
    original = Pagy::OPTIONS[:limit]
    Pagy::OPTIONS[:limit] = limit
    yield
  ensure
    Pagy::OPTIONS[:limit] = original
  end

  def capture_limits
    limits = []
    request_class = Chewy::Search::Request
    request_class.alias_method(:limit_without_capture, :limit)
    request_class.define_method(:limit) do |value|
      limits << value
      limit_without_capture(value)
    end
    yield
    limits
  ensure
    request_class.alias_method(:limit, :limit_without_capture)
    request_class.remove_method(:limit_without_capture)
  end
end

class FuneralNoticeSearchTest < ActionDispatch::IntegrationTest
  include FuneralNoticeSearchTestSupport
  parallelize(workers: 1)

  setup do
    self.class.prepare_index
  end

  class << self
    def prepare_index
      return if @index_ready

      Chewy.strategy(:urgent)
      FuneralNoticesIndex.purge!
      FuneralNoticesIndex.import!(FuneralNotice.all)
      @index_ready = true
    end
  end

  test 'returns the notice when the query adds one surname' do
    get funeral_notices_path, params: { full_name: 'norma garcia perez' }

    assert_response :success
    assert_match 'NORMA GARCIA', response.body
  end

  test 'matches an accented query to an unaccented headline' do
    get funeral_notices_path, params: { full_name: 'García' }

    assert_response :success
    assert_match 'NORMA GARCIA', response.body
  end

  test 'matches an accented headline from an unaccented query' do
    get funeral_notices_path, params: { full_name: 'Munoz' }

    assert_response :success
    assert_match 'JUAN CARLOS MUÑOZ', response.body
  end

  test 'does not stem mosqueteras into mosqueteros' do
    get funeral_notices_path, params: { content: 'mosqueteras' }

    assert_response :success
    assert_match 'NORMA GARCIA', response.body
    assert_no_match 'NESTOR ORAZI', response.body
  end

  test 'ranks a complete name above a newer partial match' do
    get funeral_notices_path, params: { full_name: 'maximiliano garcia' }
    titles = css_select('h2').map { |node| node.text.strip }

    assert_equal 'MAXIMILIANO GARCIA', titles.first
    assert_operator titles.rindex('MAXIMILIANO GARCIA'), :<, titles.index('ISAAC GARCIA')
  end

  test 'orders equal scores by published date' do
    get funeral_notices_path, params: { full_name: 'maximiliano garcia' }

    assert_equal 'Publicado el 30 de octubre de 2024', css_select('p.text-sm.mb-2').first.text.strip
  end

  test 'marks each token in the search results' do
    get funeral_notices_path, params: { full_name: 'garcia norma' }

    assert_select 'mark', text: 'NORMA'
    assert_select 'mark', text: 'GARCIA'
  end

  test 'returns a later page when the page size is stubbed to one' do
    with_page_limit(1) do
      get funeral_notices_path, params: { full_name: 'maximiliano garcia', page: 2 }

      assert_response :success
      assert_match 'Publicado el 29 de octubre de 2023', response.body
      assert_select 'p', text: /Resultados/ do |nodes|
        numbers = nodes.first.css('strong').map { |node| node.text.to_i }
        assert_equal 2, numbers.first
        assert_operator numbers.last, :>, 1
      end
    end
  end

  test 'requests the page from elasticsearch instead of a 500 hit cap' do
    limits = capture_limits { get funeral_notices_path, params: { full_name: 'garcia' } }

    assert_response :success
    assert_includes limits, Pagy::OPTIONS[:limit]
    assert_not_includes limits, 500
  end

  test 'a name prefix matches that surname and marks the whole word' do
    get funeral_notices_path, params: { full_name: 'Garc' }

    assert_response :success
    assert_match 'NORMA GARCIA', response.body
    assert_match 'ADRIANA GARCE', response.body
    assert_no_match 'LAURA GARI', response.body
    assert_no_match 'MARGARITA NIGRA', response.body
    assert_select 'mark', text: 'GARCIA'
    assert_select 'mark', text: 'GARCE'
  end

  test 'explains the name and notice text fields' do
    get funeral_notices_path

    assert_select 'label', text: 'Nombre'
    assert_select 'label', text: 'Texto del aviso'
    assert_select 'input[placeholder=?]', 'Ej.: Norma García'
    assert_select 'input[placeholder=?]', 'Ej.: mosqueteras'
    assert_match 'Se puede buscar por el comienzo del apellido, como Garc.', response.body
    assert_no_match 'Tom Marvolo Riddle', response.body
    assert_no_match 'tu amigo Harry', response.body
    assert_no_match 'Pruebe el comienzo del apellido', response.body
  end

  test 'suggests a shorter search when nothing matches' do
    get funeral_notices_path, params: { full_name: 'zzzzqqq' }

    assert_match 'No se encontraron avisos.', response.body
    assert_match 'Pruebe el comienzo del apellido, o una palabra del texto del aviso.', response.body
  end
end
