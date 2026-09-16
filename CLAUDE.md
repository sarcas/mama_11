# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About

Manager Management 1:1 — a local tool for tracking 1:1s with teammates and prompting good questions. Built on **Hanami 2.2** (not Rails), using ROM/Sequel for persistence and SQLite as the database.

## Commands

- `bin/dev` — start the app (via foreman, runs both `web` and `assets` processes from `Procfile.dev`). Web server defaults to port 2300 (`HANAMI_PORT`).
- `bundle exec hanami server` — run just the web server.
- `bundle exec rspec` — run the full test suite.
- `bundle exec rspec spec/path/to/file_spec.rb` — run a single spec file.
- `bundle exec rspec spec/path/to/file_spec.rb:LINE` — run a single example.
- `bundle exec rubocop` — lint (config lives in `config/.rubocop-common.yml` and `config/.rubocop-permissive.yml`, merged via `.rubocop.yml`).
- `bundle exec hanami db migrate` — run pending migrations (writes `config/db/structure.sql`).
- `bundle exec hanami db prepare` — create/load the dev database from `config/db/structure.sql` and run seeds.

## Architecture

This is a **Hanami 2.2** app (single app, no slices yet), following Hanami's container/component conventions rather than Rails' MVC.

- **`app/action.rb`, `app/operation.rb`, `app/view.rb`, `app/db/{relation,repo,struct}.rb`** — base classes that all app-specific classes inherit from. Every new action/repo/relation/view should subclass these, not the underlying Hanami/ROM classes directly.
- **Actions** (`app/actions/<resource>/<verb>.rb`) — HTTP endpoints, one class per action, matching the `to:` value in `config/routes.rb` (e.g. `to: "teammate.create"` → `Mama11::Actions::Teammate::Create`). Actions declare a `params` block (dry-validation) and implement `handle(request, response)`. Dependencies (e.g. repos) are pulled in via `include Deps["repos.teammate_repo"]` — Hanami's auto-registering container/DI, not manual `require`.
- **Repos** (`app/repos/`) — the only layer that talks to relations directly; expose domain-friendly methods (`all`, `find`, `create`, `update`, `remove`) built on ROM changesets (`teammates.changeset(:create, attrs).commit`).
- **Relations** (`app/relations/`) — thin ROM schema definitions over DB tables (`schema :teammates, infer: true`). Don't put business logic here.
- **Views** (`app/views/<resource>/<action>.rb`) — Hanami::View classes that `expose` data to templates, often pulling from a repo via `Deps`. Templates live in `app/templates/<resource>/<action>.html.erb`, with the shared layout at `app/templates/layouts/app.html.erb`.
- **Routes** — all defined centrally in `config/routes.rb` using Hanami's router DSL; action lookup is by the `to:` string, mapped to the `Mama11::Actions::...` namespace.
- **Migrations** — plain ROM::SQL migrations under `config/db/migrate/`, generated/run via `hanami db migrate`. `config/db/structure.sql` is the checked-in schema snapshot and should be regenerated (not hand-edited) whenever migrations change.
- **Settings** — `config/settings.rb` defines app-wide settings using `Hanami::Settings` + `Types::Params`; types live in `lib/mama_11/types.rb`.

## Testing conventions

- Specs mirror the `app/` structure under `spec/` (`spec/actions/...`, `spec/repos/...`).
- `spec/features/` holds Capybara feature specs (`RSpec.feature`/`scenario`) driving the app end-to-end via `Capybara.app = Hanami.app`. Several scenarios in `spec/features/teammate_spec.rb` are declared but pending (no block) — these represent the not-yet-built meeting/notes/sentiment features.
- `spec/requests/` holds Rack::Test-based request specs (`type: :request`), using the shared `Rack::Test` context.
- Any spec (or `describe`/`context`) tagged `:db`, or under a `type: :feature` group, gets automatic DB cleaning between examples via `database_cleaner-sequel` (`spec/support/db/cleaning.rb`) — transactional by default, truncation for `:js` examples.
- `spec/support/operations.rb` includes `Dry::Monads[:result]` in specs so `Success`/`Failure` matchers are available directly.
- Test DB is a separate SQLite file (`db/mama_11_test.sqlite`); `spec_helper.rb` sets `HANAMI_ENV=test` before requiring `hanami/prepare`.
