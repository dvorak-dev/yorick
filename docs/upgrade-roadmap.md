# Dependency upgrade roadmap

Status: 14 October 2026. Next step is Nokogiri. This file is the source of truth for the upgrade plan. [DEVELOPMENT.md](../DEVELOPMENT.md) and [PRODUCTION.md](../PRODUCTION.md) stay on the versions that are running until each item ships.

Work in this order. Each step lands on its own branch.

## 1. Rack — done 14 October 2026

`3.1.16` → `3.1.22` on branch `upgrade-rack`.

`3.1.22` is the latest 3.1 patch. It includes the `3.1.21` fixes (CVE-2026-34829, CVE-2026-34785, CVE-2026-34786) and CVE-2026-26962. Stayed off 3.2, which removes APIs this review did not cover.

Pin: [Gemfile.lock](../Gemfile.lock).

## 2. Nokogiri

`1.18.8` → `1.19.4` or newer.

CVE-2026-57235 (out-of-bounds read) and CVE-2026-57438 (use-after-free) are fixed in `1.19.4`.

Pin: [Gemfile.lock](../Gemfile.lock).

## 3. Ruby

`3.2.8` → `3.4.11`.

Ruby 3.2 ended on 1 April 2026. The last release was `3.2.11`, which included the zlib fix for CVE-2026-27820. This pin is behind that release.

Skip 3.3 (security-only until about 31 March 2027) and 4.0 (`cgi` is no longer a default gem; `sitemap_generator` has failed on 4.0). Do this while the app is still on Rails 7.1. Rails 7.1 boots on 3.4, and Rails 8.1 recommends it.

Pins: [Gemfile](../Gemfile), [.ruby-version](../.ruby-version), [Dockerfile](../Dockerfile), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml).

## 4. Node.js

18 → 24.

Node 18 ended on 30 April 2025. Node 20 ended on 30 April 2026. Node 22 ends on 30 April 2027. Node 24 is supported until 30 April 2028.

Pins: [mcp-server/Dockerfile](../mcp-server/Dockerfile), [mcp-server/Dockerfile.prod](../mcp-server/Dockerfile.prod), [mcp-server/Dockerfile.dev](../mcp-server/Dockerfile.dev).

## 5. Rails

`7.1.5.1` → `8.1`, one minor at a time: 7.2, then 8.0, then 8.1.

| Line | Security fixes |
| --- | --- |
| 7.1 | Ended 1 October 2025. Last release was 7.1.6. |
| 7.2 | Ended 9 August 2026 |
| 8.0 | Ends 7 November 2026 |
| 8.1 | Until 10 October 2027 |

The 8.1 hop requires ViewComponent 4. `view_component` `3.23.2` depends on Active Support `< 8.1`.

Pin: [Gemfile](../Gemfile) (`~> 7.1.5`).

## 6. Elasticsearch

Server `8.13.4` → `8.19.23`. Stay on 8.x. The 8.19 line is supported until 15 July 2027. Chewy 8 does not support Elasticsearch 9.

Pins: [docker-compose.yml](../docker-compose.yml), [docker-compose.prod.yml](../docker-compose.prod.yml), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml).

After Rails is at least 7.2:

- Chewy `7.2.7` → 8
- `elasticsearch` gem `7.13.3` → `>= 8.14, < 9` (Faraday 1.x leaves with this client)
- `@elastic/elasticsearch` `8.13.0` → 8.19 in [mcp-server/package.json](../mcp-server/package.json)

The server move can happen before the client move. The 7.x Ruby client is already an unsupported pairing with the 8.13 server.

## 7. MCP SDK

`@modelcontextprotocol/sdk` `1.16.0` → `1.32.1`, then v2.

`1.32.1` is the same package. v1 maintenance runs until about January 2027. v2 replaces it with `@modelcontextprotocol/server` and `@modelcontextprotocol/express`. Express stays on 5; bump it to `^5.2.1` with the v1 update. Zod 3.25 is still accepted.

Pin: [mcp-server/package.json](../mcp-server/package.json).

## Deferred

PostgreSQL 15 is supported until 11 November 2027. Plan a major before then. `postgres:15` and `postgres:15-alpine` already float to the current 15.x minor.

Puma `6.6.0` is folded into the Rails upgrade. CVE-2026-47737 applies only when PROXY protocol v1 is enabled, which this app does not set.

Tailwind, Pagy, Sprockets, Turbo, and Stimulus are out of this plan.
