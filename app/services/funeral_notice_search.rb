module FuneralNoticeSearch
  STOPWORDS = %w[de del la las los y e vda viuda].freeze
  FULL_MATCH_BOOST = 4
  PARTIAL_MATCH_BOOST = 1
  PREFIX_MATCH_BOOST = 0.5
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
    clauses << prefix_clause(tokens) if field == 'full_name'
    { bool: { should: clauses, minimum_should_match: 1 } }
  end

  def highlight_pattern(query)
    tokens = significant_tokens(query)
    return if tokens.empty?

    Regexp.union(tokens.map { |token| token_pattern(token) })
  end

  def match_clauses(field, tokens)
    clauses = [match_clause(field, tokens, boost: FULL_MATCH_BOOST, operator: 'and')]
    return clauses if tokens.one?

    clauses << match_clause(
      field,
      tokens,
      boost: PARTIAL_MATCH_BOOST,
      minimum_should_match: tokens.size - 1
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

  def match_clause(field, tokens, boost:, operator: nil, minimum_should_match: nil)
    options = { query: tokens.join(' '), boost: boost }
    options[:operator] = operator if operator
    options[:minimum_should_match] = minimum_should_match if minimum_should_match
    { match: { field => options } }
  end

  def token_pattern(token)
    letters = token.chars.map { |char| "[#{ACCENTS.fetch(char, Regexp.escape(char))}]" }.join
    /(?<![[:alnum:]])#{letters}[[:alnum:]]*/i
  end
end
