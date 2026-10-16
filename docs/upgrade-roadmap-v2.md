# Dependency upgrade roadmap v2

Status: 16 October 2026. Next step is the frontend gems. This file is the source of truth for the next upgrade plan. [upgrade-roadmap.md](upgrade-roadmap.md) is the record of the finished work. [DEVELOPMENT.md](../DEVELOPMENT.md) and [PRODUCTION.md](../PRODUCTION.md) stay on the versions that are running until each item ships.

Work in this order. Each step lands on its own branch.

## 1. Puma

`6.6.0` → `7.2.1`, then `8.0.2`.

Puma supports only the latest 7.x and 8.x. `6.6.0` is unsupported. CVE-2026-47736 and CVE-2026-47737 apply only when PROXY protocol v1 is enabled, which this app does not set.

### 7.2.1 — done 16 October 2026

`6.6.0` → `7.2.1`. Rack stayed at `3.1.22`. `config/puma.rb` was left unchanged. In cluster mode, Puma 7 preloads the app before forking.

Pin: [Gemfile](../Gemfile) (`~> 7.2.1`).

### 8.0.2 — done 16 October 2026

`7.2.1` → `8.0.2`. Rack stayed at `3.1.22`. [config/puma.rb](../config/puma.rb) pins the listen host to `0.0.0.0`, because Puma 8 otherwise binds IPv6 (`::`) when that interface exists.

Pin: [Gemfile](../Gemfile) (`~> 8.0.2`).

## 2. sitemap_generator — done 16 October 2026

`6.3.0` → `7.1.1`.

Version 7 finalizes `Sitemap.create` only when a block is given, and the default search-engine list is empty. [lib/tasks/sitemap.rake](../lib/tasks/sitemap.rake) now runs [config/sitemap.rb](../config/sitemap.rb) through `SitemapGenerator::Interpreter.run`. That file already calls `create` with a block. The app does not ping search engines. Version 6.3 loaded `cgi/session`, which blocked Ruby 4.

Pin: [Gemfile](../Gemfile) (`~> 7.1.1`).

## 3. Ruby — done 16 October 2026

`3.4.11` → `4.0.7`.

`4.0.7` is the current stable release. `4.1.0-preview1` was skipped. `CGI.escape` still comes from `cgi/escape`, which Ruby 4 keeps, so the `cgi` gem was not added. Bundler stays at `2.6.5`. `unicode-emoji` moved from `4.0.4` to `4.3.0` because `4.0.4` requires Ruby `< 4.0`. Rack stayed at `3.1.22`.

Pins: [Gemfile](../Gemfile), [.ruby-version](../.ruby-version), [Dockerfile](../Dockerfile), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml).

## 4. PostgreSQL — done 16 October 2026

15 → 16. The image tags are `postgres:16` and `postgres:16-alpine` (16.15). The `pg` gem is `1.7.0`. Rack stayed at `3.1.22`.

Support ends 11 November 2027 for 15 and 9 November 2028 for 16. The data directories were not migrated. The production cutover is in [postgres-16-migration.md](postgres-16-migration.md). A 16 container will not start on a 15 volume. Do not delete `db_data` or `postgres_data`.

Pins: [docker-compose.yml](../docker-compose.yml) (`postgres:16`), [docker-compose.prod.yml](../docker-compose.prod.yml) (`postgres:16-alpine`), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml), [Gemfile](../Gemfile) (`~> 1.7.0`).

## 5. Pagy — done 16 October 2026

`9.3.4` → `43.7.1`.

Controllers call `pagy(:offset, collection)`. `Pagy::Backend`, `Pagy::Frontend`, and the 9.x extras are gone. The page size stays 50 through `Pagy::OPTIONS[:limit]`. Views use `@pagy.previous`. Rack stayed at `3.1.22`.

Pin: [Gemfile](../Gemfile) (`~> 43.7.1`).

## 6. Frontend

One step:

- `tailwindcss-rails` `4.2.3` → `4.6.0`
- `turbo-rails` `2.0.16` → `2.0.23`
- `importmap-rails` `2.1.0` → `2.2.3`

Pins: [Gemfile](../Gemfile).

## Out of this plan

Rack stays at `3.1.22`. Elasticsearch stays on 8.x while Chewy 8 cannot speak to Elasticsearch 9. Sprockets `4.2.2` is current; Propshaft is a pipeline change. Stimulus `1.3.4` is already current. Node 24 is supported until 30 April 2028.
