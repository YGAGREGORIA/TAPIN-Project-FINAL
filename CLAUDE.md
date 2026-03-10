# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TAPIN is a fitness studio management platform (Le Wagon final project) built with Rails 8.1.2 and Ruby 3.3.5. It integrates with the Mindbody API to manage classes/bookings, and includes AI chat, a points/rewards system, and studio deal management.

## Commands

```bash
# Start development server (with all processes)
bin/dev

# Database
bin/rails db:create db:migrate     # set up fresh
bin/rails db:migrate               # apply new migrations
bin/rails db:test:prepare          # prepare test DB

# Testing
bin/rails test                     # run all unit/integration tests
bin/rails test test/models/user_test.rb   # run a single test file
bin/rails test:system              # run system (browser) tests

# Linting & security
bin/rubocop                        # lint Ruby (omakase style)
bin/brakeman --no-pager            # static security analysis
bin/bundler-audit                  # check gems for known CVEs
bin/importmap audit                # check JS dependencies
```

## Architecture

### Two User Roles
The app has a dual-sided model: **studio owners** (who create/manage studios) and **members** (who book classes, earn points, claim deals). Both use the same `User` model with Devise authentication.

### Core Domain Model
- **Studio** — central entity, belongs to a `User` (owner). Has `mindbody_site_id` and `mindbody_api_key` for Mindbody integration, and a `slug`.
- **StudioBrand** — one-to-one branding config per studio (colors, fonts, logo, tagline, brand tone). Used for white-labeling the member experience.
- **ClassConfig** — defines a class type within a studio (with `mindbody_class_id`, `point_value`, `is_premium`). Controls how many points a visit earns.
- **Visit** — records a user attending a class (`belongs_to :class_config`). Stores `points_earned` and `visited_at`.
- **Booking** — a class reservation (`mindbody_booking_id`, `class_name`, `class_time`, `status`).
- **Deal** — studio-created discount offers with `trigger_condition`, `deal_type`, `discount_percent`, `expiry_days`, and `usage_limit`.
- **DealClaim** — a user claiming a deal; has a `code` and `status`. Also `belongs_to :studio` directly (in addition to via deal).
- **Reward** — redeemable rewards offered by a studio with a `points_cost`.
- **RewardRedemption** — a user redeeming a reward using points (`point_spent`, `code`, `status`).
- **Chat / Message** — AI chat sessions between a user and a studio. Messages have `role`, `content`, `sentiment`, `tag`, and `summary` columns, suggesting AI-analyzed conversations.

### Key Gems & Infrastructure
- **Devise** — authentication (database_authenticatable, registerable, recoverable, rememberable, validatable)
- **Hotwire** (Turbo + Stimulus) — frontend interactivity without a JS framework
- **Importmap** — JavaScript without bundling
- **Propshaft** — asset pipeline
- **Solid Cache / Solid Queue / Solid Cable** — database-backed adapters (no Redis required)
- **Kamal** — deployment via Docker containers
- **Capybara + Selenium** — system testing

### Routes
Currently minimal — only Devise routes and a `root to: "pages#home"` are defined. Most application routes are yet to be built.

### Style
RuboCop uses the `rubocop-rails-omakase` ruleset (Rails' official opinionated style). Run `bin/rubocop -a` to auto-correct offenses.
