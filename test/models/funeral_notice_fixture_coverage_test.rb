require 'test_helper'

class FuneralNoticeFixtureCoverageTest < ActiveSupport::TestCase
  test 'keeps the original placeholder rows' do
    assert_equal 'abc123', funeral_notices(:one).hash_id
    assert_equal 'def456', funeral_notices(:two).hash_id
  end

  test 'includes plain surnames and the same person on more than one date' do
    assert_equal 'NORMA GARCIA', funeral_notices(:norma_garcia_4e7977).full_name
    assert_equal 'ISAAC GARCIA', funeral_notices(:isaac_garcia_51e9a5).full_name
    dates = FuneralNotice.where(full_name: 'MAXIMILIANO GARCIA').distinct.pluck(:published_on)
    assert_operator dates.size, :>, 1
  end

  test 'includes particles, a nickname, and two surnames' do
    assert_includes funeral_notices(:nelida_teresa_garcia_vda_de_garcia_tota_e584c9).full_name, '(Tota)'
    assert_equal 'GUILLERMO GARCIA CEPPI', funeral_notices(:guillermo_garcia_ceppi_b88efa).full_name
    assert_equal 'FRANCISCA GARCIA RODRIGUEZ', funeral_notices(:francisca_garcia_rodriguez_5a9094).full_name
  end

  test 'includes an accented headline and a body accent under an unaccented name' do
    assert_includes funeral_notices(:juan_carlos_munoz_1c7826).full_name, 'Ñ'
    notice = funeral_notices(:maximo_garcia_b2aea7)
    assert_no_match(/[áéíóúñ]/i, notice.full_name)
    assert_includes notice.content, 'García'
  end

  test 'includes prefix neighbors and words that must not stem together' do
    assert_equal 'ADRIANA GARCE', funeral_notices(:adriana_garce_19ad93).full_name
    assert_equal 'LAURA GARI', funeral_notices(:laura_gari_fe651d).full_name
    assert_includes funeral_notices(:margarita_nigra_gara_2e4eab).full_name, 'Gara'
    assert_includes funeral_notices(:norma_garcia_4e7977).content.downcase, 'mosqueteras'
    orazi = funeral_notices(:nestor_orazi_42a4d3).content.downcase
    assert_includes orazi, 'mosqueteros'
    assert_not_includes orazi, 'mosqueteras'
  end

  test 'includes a mention of someone else, an apostrophe, and an initial' do
    assert_includes funeral_notices(:mario_garcia_878c13).content, 'Margarita'
    assert_match(/O['’]/, funeral_notices(:maximo_garcia_b2aea7).content)
    assert_includes funeral_notices(:fermin_garcia_aa918a).content, 'Ma.'
  end

  test 'does not invent a hyphenated headline' do
    curated = FuneralNotice.where.not(hash_id: %w[abc123 def456])
    assert(curated.none? { |notice| notice.full_name.include?('-') })
  end
end
