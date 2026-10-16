require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'marks each token when the query order differs from the name' do
    highlighted = highlight_search_terms('NORMA GARCIA', 'garcia norma')

    assert_includes highlighted, '<mark>NORMA</mark>'
    assert_includes highlighted, '<mark>GARCIA</mark>'
  end

  test 'marks an unaccented name for an accented query' do
    highlighted = highlight_search_terms('NORMA GARCIA', 'García')

    assert_includes highlighted, '<mark>GARCIA</mark>'
  end

  test 'marks the whole surname when the query is a prefix' do
    garcia = highlight_search_terms('NORMA GARCIA', 'Garc')
    garce = highlight_search_terms('ADRIANA GARCE', 'Garc')

    assert_includes garcia, '<mark>GARCIA</mark>'
    assert_includes garce, '<mark>GARCE</mark>'
  end

  test 'skips particles that are not part of the name match' do
    highlighted = highlight_search_terms('GARCIA VDA. DE PEREZ', 'garcia vda de')

    assert_includes highlighted, '<mark>GARCIA</mark>'
    assert_not_includes highlighted, '<mark>VDA</mark>'
    assert_not_includes highlighted, '<mark>DE</mark>'
  end
end
