require 'test_helper'

module FuneralNoticeSearchTestSupport
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def prepare_index
      return if @index_ready

      Chewy.strategy(:urgent)
      FuneralNoticesIndex.purge!
      FuneralNoticesIndex.import!(FuneralNotice.all)
      @index_ready = true
    end
  end

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

# rubocop:disable Metrics/ClassLength
class FuneralNoticeSearchTest < ActionDispatch::IntegrationTest
  include FuneralNoticeSearchTestSupport
  parallelize(workers: 1)

  setup do
    self.class.prepare_index
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

  test 'a misspelled surname ranks that person above a shared given name' do
    get funeral_notices_path, params: { full_name: 'maria garca' }
    titles = css_select('h2').map { |node| node.text.strip }

    assert_operator titles.index('MARIA GARCIA'), :<, titles.index('MARIA CRISTINA DEL VALLE')
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

  test 'newest publication date leads when that order is selected' do
    get funeral_notices_path, params: { full_name: 'maximiliano garcia', order: 'desc' }
    titles = css_select('h2').map { |node| node.text.strip }

    assert_equal 'NORMA GARCIA', titles.first
    assert_equal 'Publicado el 22 de diciembre de 2024', css_select('p.text-sm.mb-2').first.text.strip
    assert_operator titles.index('NORMA GARCIA'), :<, titles.index('MAXIMILIANO GARCIA')
  end

  test 'oldest publication date leads when that order is selected' do
    get funeral_notices_path, params: { full_name: 'maximiliano garcia', order: 'asc' }

    assert_equal 'REINA ROSA DI FRANCESCO Vda. de GARCIA (Lala)', css_select('h2').first.text.strip
    assert_equal 'Publicado el 24 de octubre de 2013', css_select('p.text-sm.mb-2').first.text.strip
  end

  test 'the plain listing can start with the oldest notice' do
    with_page_limit(1) do
      get funeral_notices_path, params: { order: 'asc' }

      assert_equal 'LAURA GARI', css_select('h2').first.text.strip
      assert_match 'order=asc', css_select('a[rel="next"]').first['href']
      assert_select '[data-search-filters-applied-value=?]', 'true'
      assert_select 'a', text: 'Más antiguos'
      assert_select 'a', text: 'Relevancia', count: 0
    end
  end

  test 'a search offers relevance and keeps the chosen date order' do
    get funeral_notices_path, params: { full_name: 'garcia', order: 'asc' }

    assert_select 'a[aria-current]', text: 'Más antiguos'
    assert_select 'a', text: 'Relevancia'
    assert_select 'input[name="order"][value="asc"]'
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

  test 'a misspelled long surname still finds the notice' do
    %w[ZAPETINNI ZAPETTINI ZAPPETINI ZAPPETTINNI].each do |query|
      get funeral_notices_path, params: { full_name: query }

      assert_response :success
      assert_match 'ZAPPETTINI', response.body
    end
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

  test 'keeps the active filters readable when they can be collapsed' do
    get funeral_notices_path, params: { full_name: 'garcia', year_from: 2013, year_to: 2014 }

    assert_select 'button[aria-expanded=true]', text: 'Ocultar filtros'
    assert_select '[data-search-filters-applied-value=?]', 'true'
    assert_select '[data-search-filters-target=summary]',
                  text: 'Nombre: garcia · Publicado: 2013–2014 · Orden: Relevancia'
  end

  test 'explains the name and notice text fields' do
    get funeral_notices_path

    assert_select '[data-search-filters-applied-value=?]', 'false'
    assert_select 'label', text: 'Nombre'
    assert_select 'label', text: 'Texto del aviso'
    assert_select 'legend', text: 'Publicado entre'
    assert_select 'input[placeholder=?]', 'Nombre completo. Ej: Tom Marvolo Riddle'
    assert_select 'input[placeholder=?]', 'Contenido. Ej: tu amigo Harry'
    assert_select 'input[placeholder=?]', '2016'
    assert_select 'input[placeholder=?]', '2017'
    assert_match 'Se puede buscar por el comienzo del apellido, como Ridd.', response.body
    assert_no_match 'Pruebe el comienzo del apellido', response.body
  end

  test 'limits a name to the publication years' do
    get funeral_notices_path, params: { full_name: 'maximiliano garcia', year_from: 2013, year_to: 2014 }

    assert_response :success
    assert_match 'Publicado el 31 de octubre de 2013', response.body
    assert_no_match 'Publicado el 30 de octubre de 2024', response.body
  end

  test 'requires both the name and the notice text' do
    get funeral_notices_path, params: { full_name: 'norma garcia', content: 'mosqueteros' }

    assert_no_match 'NORMA GARCIA', response.body

    get funeral_notices_path, params: { full_name: 'norma garcia', content: 'mosqueteras' }

    assert_match 'NORMA GARCIA', response.body
  end

  test 'suggests a shorter search when nothing matches' do
    get funeral_notices_path, params: { full_name: 'zzzzqqq' }

    assert_match 'No se encontraron avisos.', response.body
    assert_match 'Pruebe el comienzo del apellido, o una palabra del texto del aviso.', response.body
  end
end
# rubocop:enable Metrics/ClassLength
