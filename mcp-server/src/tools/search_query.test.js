import assert from 'node:assert/strict';
import test from 'node:test';
import { buildSearchRequest, significantTokens } from './search_query.js';

function requestBody(args) {
  return buildSearchRequest(args).body;
}

test('Garc is a name prefix clause', () => {
  const body = requestBody({ full_name: 'Garc' });
  const name = body.query.bool.should[0];
  const prefix = name.bool.should.find((clause) => clause.multi_match);

  assert.equal(prefix.multi_match.type, 'bool_prefix');
  assert.equal(prefix.multi_match.query, 'garc');
  assert.deepEqual(prefix.multi_match.fields, [
    'full_name',
    'full_name._2gram',
    'full_name._3gram',
  ]);
  const encoded = JSON.stringify(body);

  assert.equal(encoded.includes('fuzziness'), false);
  assert.equal(encoded.includes('name_metaphones'), false);
});

test('norma garcia perez still matches when one surname is extra', () => {
  const body = requestBody({ full_name: 'norma garcia perez' });
  const clauses = body.query.bool.should[0].bool.should;
  const partial = clauses.find((clause) => clause.match?.full_name?.minimum_should_match === 2);

  assert.equal(partial.match.full_name.query, 'norma garcia perez');
  assert.equal(JSON.stringify(partial).includes('fuzziness'), false);
});

test('a multi-word name allows a small spelling error', () => {
  const body = requestBody({ full_name: 'maria garca' });
  const clauses = body.query.bool.should[0].bool.should;
  const fuzzy = clauses.find((clause) => clause.match?.full_name?.fuzziness === 'AUTO');

  assert.equal(fuzzy.match.full_name.query, 'maria garca');
  assert.equal(fuzzy.match.full_name.operator, 'and');
  assert.equal(fuzzy.match.full_name.boost, 2);
  assert.equal(fuzzy.match.full_name.prefix_length, 1);
  assert.equal(fuzzy.match.full_name.max_expansions, 50);
});

test('a long misspelled surname uses fuzziness and a phonetic code', () => {
  const body = requestBody({ full_name: 'ZAPETINNI' });
  const clauses = body.query.bool.should[0].bool.should;
  const fuzzy = clauses.find((clause) => clause.match?.full_name?.fuzziness === 'AUTO');
  const phonetic = clauses.find((clause) => clause.bool?.must);

  assert.equal(fuzzy.match.full_name.query, 'zapetinni');
  assert.equal(fuzzy.match.full_name.boost, 2);
  assert.equal(phonetic.bool.boost, 1);
  assert.deepEqual(phonetic.bool.must, [{ term: { name_metaphones: 'SPTN' } }]);
});

test('content search does not use fuzziness or a prefix', () => {
  const body = requestBody({ content: 'mosqueteras' });
  const encoded = JSON.stringify(body);

  assert.equal(encoded.includes('fuzziness'), false);
  assert.equal(encoded.includes('name_metaphones'), false);
  assert.equal(encoded.includes('bool_prefix'), false);
  assert.equal(encoded.includes('mosqueteros'), false);
  assert.match(encoded, /mosqueteras/);
});

test('sorts by score and then published date', () => {
  const body = requestBody({ query: 'garcia' });

  assert.deepEqual(body.sort, [
    { _score: { order: 'desc' } },
    { published_on: { order: 'desc' } },
  ]);
  assert.equal(body.query.bool.should.length, 2);
});

test('full_name wins when query is also sent', () => {
  const encoded = JSON.stringify(requestBody({ query: 'gari', full_name: 'Garc' }));

  assert.match(encoded, /garc/);
  assert.equal(encoded.includes('gari'), false);
});

test('pages fifty results at a time', () => {
  const body = requestBody({ query: 'garcia', limit: 500, page: 2 });

  assert.equal(body.size, 50);
  assert.equal(body.from, 50);
});

test('drops name particles before searching', () => {
  assert.deepEqual(significantTokens('Nelida vda. de García'), ['nelida', 'garcia']);
});

test('requires a search parameter', () => {
  assert.equal(buildSearchRequest({}), null);
});
