# Primary Double Metaphone code, capped at four characters.
# rubocop:disable Metrics/ClassLength
class NameMetaphone
  MAX_LENGTH = 4

  def self.primary(word)
    new(word).primary
  end

  def initialize(word)
    @word = word.to_s.upcase.gsub(/[^A-Z]/, '')
    @word = @word[1..] || '' if @word.start_with?('GN', 'KN', 'PN', 'WR', 'PS')
    @code = +''
    @index = 0
  end

  def primary
    consume until @index >= @word.length || @code.length >= MAX_LENGTH
    @code
  end

  private

  def consume
    send(rule_for(current))
  end

  def rule_for(char)
    return :vowel if 'AEIOUY'.include?(char)
    return :skip if char.nil?

    {
      'B' => :bee, 'C' => :cee, 'D' => :dee, 'F' => :eff, 'G' => :gee,
      'H' => :aitch, 'J' => :jay, 'K' => :kay, 'L' => :ell, 'M' => :em,
      'N' => :en, 'P' => :pee, 'Q' => :queue, 'R' => :ar, 'S' => :ess,
      'T' => :tee, 'V' => :vee, 'W' => :skip_one, 'X' => :ex, 'Z' => :zee
    }.fetch(char, :skip_one)
  end

  def vowel
    add('A') if @index.zero?
    @index += 1
  end

  def bee
    add('P')
    advance('B')
  end

  def cee
    add(front_vowel? ? 'S' : 'K')
    @index += 1
  end

  def dee
    add('T')
    advance('D')
  end

  def eff
    add('F')
    advance('F')
  end

  def gee
    add(front_vowel? ? 'J' : 'K')
    advance('G')
  end

  def aitch
    @index += 1
  end

  def jay
    add('J')
    @index += 1
  end

  def kay
    add('K')
    advance('K')
  end

  def ell
    add('L')
    advance('L')
  end

  def em
    add('M')
    advance('M')
  end

  def en
    add('N')
    advance('N')
  end

  def pee
    add('F') if ahead == 'H'
    add('P') unless ahead == 'H'
    @index += ahead == 'H' ? 2 : 1
    advance('P') if ahead(0) == 'P'
  end

  def queue
    add('K')
    @index += 1
  end

  def ar
    add('R')
    advance('R')
  end

  def ess
    add('S')
    advance('S')
  end

  def tee
    add('T')
    advance('T')
  end

  def vee
    add('F')
    @index += 1
  end

  def ex
    add('KS')
    @index += 1
  end

  def zee
    add('S')
    advance('Z')
  end

  def skip_one
    @index += 1
  end

  def skip
    @index += 1
  end

  def advance(char)
    @index += ahead == char ? 2 : 1
  end

  def front_vowel?
    ahead.present? && 'EIY'.include?(ahead)
  end

  def add(text)
    @code << text
    @code.slice!(MAX_LENGTH..)
  end

  def current
    @word[@index]
  end

  def ahead(offset = 1)
    @word[@index + offset]
  end
end
# rubocop:enable Metrics/ClassLength
