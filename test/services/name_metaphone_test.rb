require 'test_helper'

class NameMetaphoneTest < ActiveSupport::TestCase
  test 'the Zappettini spellings share one code' do
    codes = %w[ZAPPETTINI ZAPETTINI ZAPPETINI ZAPPETTINNI ZAPETINNI].map do |spelling|
      NameMetaphone.primary(spelling)
    end

    assert_equal ['SPTN'], codes.uniq
  end

  test 'a short prefix stays distinct from a different ending' do
    assert_equal 'KRK', NameMetaphone.primary('GARC')
    assert_equal 'KRS', NameMetaphone.primary('GARCIA')
    assert_equal 'KR', NameMetaphone.primary('GARI')
  end
end
