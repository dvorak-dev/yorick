const STOPWORDS = new Set(['de', 'del', 'la', 'las', 'los', 'y', 'e', 'vda', 'viuda']);
const FULL_MATCH_BOOST = 4;
const PARTIAL_MATCH_BOOST = 1;
const PREFIX_MATCH_BOOST = 0.5;
const DEFAULT_PAGE_SIZE = 50;

function significantTokens(text) {
  const folded = String(text).normalize('NFD').replace(/\p{M}/gu, '').toLowerCase();
  return (folded.match(/[a-z0-9]+/g) || []).filter((token) => !STOPWORDS.has(token));
}

function matchClause(field, tokens, boost, extra) {
  return {
    match: {
      [field]: {
        query: tokens.join(' '),
        boost,
        ...extra,
      },
    },
  };
}

function matchClauses(field, tokens) {
  const clauses = [matchClause(field, tokens, FULL_MATCH_BOOST, { operator: 'and' })];
  if (tokens.length > 1) {
    clauses.push(matchClause(field, tokens, PARTIAL_MATCH_BOOST, {
      minimum_should_match: tokens.length - 1,
    }));
  }
  return clauses;
}

function prefixClause(tokens) {
  return {
    multi_match: {
      query: tokens.join(' '),
      type: 'bool_prefix',
      fields: ['full_name', 'full_name._2gram', 'full_name._3gram'],
      operator: 'and',
      boost: PREFIX_MATCH_BOOST,
    },
  };
}

function fieldQuery(field, text) {
  const tokens = significantTokens(text);
  if (tokens.length === 0) return null;

  const clauses = matchClauses(field, tokens);
  if (field === 'full_name') clauses.push(prefixClause(tokens));
  return { bool: { should: clauses, minimum_should_match: 1 } };
}

function pageWindow(page, limit) {
  const size = Math.min(Math.max(Number(limit) || DEFAULT_PAGE_SIZE, 1), DEFAULT_PAGE_SIZE);
  const currentPage = Math.max(Number(page) || 1, 1);
  return { from: (currentPage - 1) * size, size, page: currentPage };
}

function buildSearchRequest(args = {}) {
  const nameText = args.full_name || args.query;
  const contentText = args.content || (args.full_name ? null : args.query);
  if (!nameText && !contentText) return null;

  const clauses = [];
  if (nameText) {
    const nameQuery = fieldQuery('full_name', nameText);
    if (nameQuery) clauses.push(nameQuery);
  }
  if (contentText) {
    const contentQuery = fieldQuery('content', contentText);
    if (contentQuery) clauses.push(contentQuery);
  }
  const { from, size, page } = pageWindow(args.page, args.limit);
  const filter = [];
  if (args.date_from || args.date_to) {
    const range = { published_on: {} };
    if (args.date_from) range.published_on.gte = args.date_from;
    if (args.date_to) range.published_on.lte = args.date_to;
    filter.push({ range });
  }

  return {
    index: process.env.ELASTICSEARCH_INDEX || 'yorick_production_funeral_notices',
    page,
    empty: clauses.length === 0,
    body: {
      query: {
        bool: {
          should: clauses,
          minimum_should_match: clauses.length === 0 ? 0 : 1,
          filter,
        },
      },
      sort: [
        { _score: { order: 'desc' } },
        { published_on: { order: 'desc' } },
      ],
      from,
      size,
    },
  };
}

export {
  significantTokens,
  buildSearchRequest,
};
