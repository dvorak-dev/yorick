import { db, es } from '../config/database.js';
import { buildSearchRequest } from './search_query.js';

function searchLabel(args) {
  return [args.full_name, args.content, args.query].filter(Boolean).join(' / ');
}

function hitId(hit) {
  const raw = hit._source?.id ?? hit._id;
  const id = Number(raw);
  return Number.isInteger(id) ? id : null;
}

async function loadNotices(ids) {
  if (ids.length === 0) return [];

  const result = await db.query(
    `SELECT id, hash_id, full_name, content, published_on, source_link
     FROM funeral_notices
     WHERE id = ANY($1::int[])`,
    [ids],
  );
  return result.rows;
}

function emptySearch(label) {
  return {
    content: [
      {
        type: 'text',
        text: `Found 0 funeral notices matching "${label}"`,
      },
    ],
    isError: false,
    metadata: {
      total_results: 0,
      page: 1,
      results: [],
    },
  };
}

async function searchFuneralNotices(args) {
  const request = buildSearchRequest(args);
  if (!request) {
    throw new Error('A search parameter is required');
  }

  const label = searchLabel(args);
  if (request.empty) return emptySearch(label);

  try {
    const response = await es.search({ index: request.index, body: request.body });
    const hits = response.hits.hits;
    const ids = hits.map(hitId).filter((id) => id !== null);
    const scoreById = new Map(hits.map((hit) => [hitId(hit), hit._score]));
    const notices = await loadNotices(ids);
    const byId = new Map(notices.map((notice) => [Number(notice.id), notice]));
    const results = ids.flatMap((id) => {
      const notice = byId.get(id);
      if (!notice) return [];
      return [{
        hash_id: notice.hash_id,
        full_name: notice.full_name,
        content: notice.content,
        published_on: notice.published_on,
        source_link: notice.source_link,
        score: scoreById.get(id),
      }];
    });
    const total = response.hits.total?.value ?? response.hits.total ?? 0;

    return {
      content: [
        {
          type: 'text',
          text: `Found ${results.length} of ${total} funeral notices matching "${label}"`,
        },
      ],
      isError: false,
      metadata: {
        total_results: total,
        page: request.page,
        query_time_ms: response.took,
        results,
      },
    };
  } catch (error) {
    console.error('Elasticsearch search error:', error);
    throw new Error(`Search failed: ${error.message}`);
  }
}

export {
  searchFuneralNotices,
};
