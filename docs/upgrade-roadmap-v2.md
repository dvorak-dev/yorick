# Dependency upgrade roadmap v2

Status: 16 October 2026. Next step is Ruby. This file is the source of truth for the next upgrade plan. [upgrade-roadmap.md](upgrade-roadmap.md) is the record of the finished work. [DEVELOPMENT.md](../DEVELOPMENT.md) and [PRODUCTION.md](../PRODUCTION.md) stay on the versions that are running until each item ships.

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

## 3. Ruby

`3.4.11` → `4.0.7`, only after sitemap_generator 7.

`4.0.7` is the current stable release. Skip `4.1.0-preview1`.

Pins: [Gemfile](../Gemfile), [.ruby-version](../.ruby-version), [Dockerfile](../Dockerfile), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml).

## 4. PostgreSQL

15 → 16.

Support ends 11 November 2027 for 15 and 9 November 2028 for 16. One major at a time. Production data is in `postgres_data`, so this is a dump/restore or `pg_upgrade`, not a tag float. Bump the `pg` gem (`1.5.9`) with the server.

Pins: [docker-compose.yml](../docker-compose.yml) (`postgres:15`), [docker-compose.prod.yml](../docker-compose.prod.yml) (`postgres:15-alpine`), [.github/workflows/pr-ci.yml](../.github/workflows/pr-ci.yml).

## 5. Pagy

`9.3.4` → `43.7.1`.

[app/components/pagination_component.rb](../app/components/pagination_component.rb) includes `Pagy::Frontend` and delegates `series`. [config/initializers/pagy.rb](../config/initializers/pagy.rb) loads the 9.x extras. This is an API change.

Pin: [Gemfile](../Gemfile) (`~> 9.3`).

## 6. Frontend

One step:

- `tailwindcss-rails` `4.2.3` → `4.6.0`
- `turbo-rails` `2.0.16` → `2.0.23`
- `importmap-rails` `2.1.0` → `2.2.3`

Pins: [Gemfile](../Gemfile).

## Out of this plan

Rack stays at `3.1.22`. Elasticsearch stays on 8.x while Chewy 8 cannot speak to Elasticsearch 9. Sprockets `4.2.2` is current; Propshaft is a pipeline change. Stimulus `1.3.4` is already current. Node 24 is supported until 30 April 2028.
