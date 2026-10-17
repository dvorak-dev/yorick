module FuneralNoticeSearch
  STOPWORDS = %w[de del la las los y e vda viuda].freeze
  FULL_MATCH_BOOST = 4
  FUZZY_MATCH_BOOST = 2
  PARTIAL_MATCH_BOOST = 1
  PHONETIC_MATCH_BOOST = 1
  PREFIX_MATCH_BOOST = 0.5
  PHONETIC_MIN_LENGTH = 5
  ACCENTS = {
    'a' => 'aáàäâãAÁÀÄÂÃ',
    'e' => 'eéèëêEÉÈËÊ',
    'i' => 'iíìïîIÍÌÏÎ',
    'o' => 'oóòöôõOÓÒÖÔÕ',
    'u' => 'uúùüûUÚÙÜÛ',
    'n' => 'nñNÑ',
    'c' => 'cçCÇ'
  }.freeze

  module_function

  def significant_tokens(text)
    I18n.transliterate(text.to_s).downcase.scan(/[a-z0-9]+/) - STOPWORDS
  end

  def field_query(field, text)
    tokens = significant_tokens(text)
    return if tokens.empty?

    clauses = match_clauses(field, tokens)
    if field == 'full_name'
      clauses << prefix_clause(tokens)
      clauses << phonetic_clause(tokens)
    end
    { bool: { should: clauses.compact, minimum_should_match: 1 } }
  end

  def highlight_pattern(query)
    tokens = significant_tokens(query)
    return if tokens.empty?

    Regexp.union(tokens.map { |token| token_pattern(token) })
  end

  def name_metaphones(text)
    significant_tokens(text).filter_map { |token| NameMetaphone.primary(token).presence }
  end

  def match_clauses(field, tokens)
    clauses = [match_clause(field, tokens, boost: FULL_MATCH_BOOST, operator: 'and')]
    clauses << partial_clause(field, tokens) if tokens.many?
    clauses << fuzzy_clause(field, tokens) if fuzzy_name?(field, tokens)
    clauses
  end

  def partial_clause(field, tokens)
    match_clause(field, tokens, boost: PARTIAL_MATCH_BOOST, minimum_should_match: tokens.size - 1)
  end

  def fuzzy_name?(field, tokens)
    field == 'full_name' && (tokens.many? || tokens.first.length >= PHONETIC_MIN_LENGTH)
  end

  def phonetic_clause(tokens)
    codes = phonetic_codes(tokens)
    return if codes.empty?

    {
      bool: {
        boost: PHONETIC_MATCH_BOOST,
        must: codes.map { |code| { term: { name_metaphones: code } } }
      }
    }
  end

  def phonetic_codes(tokens)
    tokens.filter_map do |token|
      next if token.length < PHONETIC_MIN_LENGTH

      NameMetaphone.primary(token).presence
    end
  end

  def fuzzy_clause(field, tokens)
    match_clause(
      field,
      tokens,
      boost: FUZZY_MATCH_BOOST,
      operator: 'and',
      fuzziness: 'AUTO',
      prefix_length: 1,
      max_expansions: 50
    )
  end

  def prefix_clause(tokens)
    {
      multi_match: {
        query: tokens.join(' '),
        type: 'bool_prefix',
        fields: %w[full_name full_name._2gram full_name._3gram],
        operator: 'and',
        boost: PREFIX_MATCH_BOOST
      }
    }
  end

  def match_clause(field, tokens, boost:, **extra)
    options = { query: tokens.join(' '), boost: boost }
    extra.each { |key, value| options[key] = value unless value.nil? }
    { match: { field => options } }
  end

  def token_pattern(token)
    letters = token.chars.map { |char| "[#{ACCENTS.fetch(char, Regexp.escape(char))}]" }.join
    /(?<![[:alnum:]])#{letters}[[:alnum:]]*/i
  end
end
