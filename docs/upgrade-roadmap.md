# Dependency upgrade roadmap

Status: 14 October 2026. The ordered upgrades are done. Deferred items remain below. This file is the source of truth for the upgrade plan. [DEVELOPMENT.md](../DEVELOPMENT.md) and [PRODUCTION.md](../PRODUCTION.md) stay on the versions that are running until each item ships.

Work in this order. Each step lands on its own branch.

## 1. Rack — done 14 October 2026

`3.1.16` → `3.1.22` on branch `upgrade-rack`.

`3.1.22` is the latest 3.1 patch. It includes the `3.1.21` fixes (CVE-2026-34829, CVE-2026-34785, CVE-2026-34786) and CVE-2026-26962. Stayed off 3.2, which removes APIs this review did not cover.

Pin: [Gemfile.lock](../Gemfile.lock).

## 2. Nokogiri — done 14 October 2026

`1.18.8` → `1.19.4` on branch `upgrade-nokogiri`.

`1.19.4` includes CVE-2026-57235 and CVE-2026-57438. Stayed off unreleased main, which changes HTML5 parsing of `iframe` and `noframes`.

Pin: [Gemfile.lock](../Gemfile.lock).

## 3. Ruby — done 14 October 2026

`3.2.8` → `3.4.11` on branch `upgrade-ruby`. Rails stays on 7.1.5.1.

Ruby 3.2 ended on 1 April 2026. Skipped 3.3 and 4.0.

Pins: [Gemfile](../Gemfile), [.ruby-version](../.ruby-version), [Dockerfile](../Dockerfile), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml).

## 4. Node.js — done 14 October 2026

18 → 24 on branch `upgrade-node`. Node 24 is supported until 30 April 2028. Skipped 20 and 22.

Pins: [mcp-server/Dockerfile](../mcp-server/Dockerfile), [mcp-server/Dockerfile.prod](../mcp-server/Dockerfile.prod), [mcp-server/Dockerfile.dev](../mcp-server/Dockerfile.dev).

## 5. Rails

`7.1.5.1` → `8.1`, one minor at a time: 7.2, then 8.0, then 8.1.

| Line | Security fixes |
| --- | --- |
| 7.1 | Ended 1 October 2025. Last release was 7.1.6. |
| 7.2 | Ended 9 August 2026. Done below. |
| 8.0 | Ends 7 November 2026. Done below. |
| 8.1 | Until 10 October 2027 |

### 7.2 — done 14 October 2026

`7.1.5.1` → `7.2.4` on branch `chore/upgrade-dependencies-p2`. `7.2.4` is the final 7.2 release.

`config.load_defaults` was left at 7.1 during this hop. Rack stayed at 3.1.22.

### 8.0 — done 14 October 2026

`7.2.4` → `8.0.5.1` on branch `chore/upgrade-dependencies-p2`. `8.0.5.1` is the latest 8.0 release.

`config.load_defaults` was set to `8.0` during this hop, which includes the 7.2 defaults. Rack stayed at 3.1.22.

### 8.1 — done 14 October 2026

`8.0.5.1` → `8.1.4` on branch `chore/upgrade-dependencies-p2`. ViewComponent `3.23.2` → `4.15.0`.

`config.load_defaults` is `8.1`. Rack stayed at 3.1.22.

Pin: [Gemfile](../Gemfile) (`~> 8.1.4`, `view_component` `~> 4.15`).

## 6. Elasticsearch — done 14 October 2026

Server `8.13.4` → `8.19.23` on branch `chore/upgrade-dependencies-p3`. Stay on 8.x. The 8.19 line is supported until 15 July 2027. Chewy 8 does not support Elasticsearch 9.

Pins: [docker-compose.yml](../docker-compose.yml), [docker-compose.prod.yml](../docker-compose.prod.yml), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml).

Clients on the same branch:

- Chewy `7.2.7` → `8.4.1`
- `elasticsearch` gem `7.13.3` → `8.19.3` (`>= 8.14, < 9`). Faraday 1.x left with the 7.x client.
- `@elastic/elasticsearch` `8.13.0` → `8.19.2` in [mcp-server/package.json](../mcp-server/package.json)

## 7. MCP SDK

`@modelcontextprotocol/sdk` `1.16.0` → `1.32.1`, then v2.

### 1.32.1 — done 14 October 2026

`1.16.0` → `1.32.1` on branch `chore/upgrade-dependencies-p3`. Express `^5.1.0` → `^5.2.1` (lock resolves `5.3.0`). Zod stayed at `3.25.76`.

`1.32.1` is the same package. v1 maintenance runs until about January 2027.

Pin: [mcp-server/package.json](../mcp-server/package.json).

### v2 — done 14 October 2026

`@modelcontextprotocol/sdk` `1.32.1` → `@modelcontextprotocol/server` `2.3.1` and `@modelcontextprotocol/node` `2.1.1` on branch `chore/upgrade-dependencies-p3`. Zod `3.25.76` → `4.6.7` (`^4.2.0`). Express stayed on 5.

The Node package supplies the Streamable HTTP transport. `@modelcontextprotocol/express` is the host-validation helper, and this server keeps its own Express app listening on `0.0.0.0`.

Pin: [mcp-server/package.json](../mcp-server/package.json).

## Deferred

PostgreSQL 15 is supported until 11 November 2027. Plan a major before then. `postgres:15` and `postgres:15-alpine` already float to the current 15.x minor.

Puma `6.6.0` is folded into the Rails upgrade. CVE-2026-47737 applies only when PROXY protocol v1 is enabled, which this app does not set.

Tailwind, Pagy, Sprockets, Turbo, and Stimulus are out of this plan.
