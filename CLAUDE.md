# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Ruby version**: 3.4.3 via rbenv. Always prefix `bin/rails` / `bundle exec` commands with `export PATH="$HOME/.rbenv/versions/3.4.3/bin:$PATH"` when running from a Bash tool, because the system ruby (2.6) is picked up otherwise.

**Dev server** (runs both together):
```
bin/dev          # starts rails server + tailwindcss:watch via Procfile.dev
```

Or separately:
```
bin/rails server
bin/rails tailwindcss:watch
```

**Tests**:
```
bundle exec rspec                                      # full suite
bundle exec rspec spec/requests/super_admin/employees_spec.rb   # single file
bundle exec rspec spec/models/product_price_spec.rb:42          # single example by line
```

**Other**:
```
bin/rails db:migrate
bin/rails db:seed          # creates super_admin, delivery admins, global settings, delivery zones
bundle exec brakeman       # security scan
bundle exec rubocop        # style check (rubocop-rails-omakase)
```

**Verifying ERB syntax** (Erubi compiles more strictly than plain `ruby -c`):
```ruby
# In a bin/rails runner script:
require "erubi"
src = File.read("path/to/template.html.erb")
RubyVM::InstructionSequence.compile(Erubi::Engine.new(src, escape: true).src)
```
Note: Erubi will false-positive on `form_with ... do |f|` blocks — that is a known non-issue; Rails patches this at render time.

---

## Architecture

### Portal structure

The app has four distinct access layers, each with its own `namespace` and `BaseController`:

| Namespace | Base auth | Layout | Entry point |
|---|---|---|---|
| *(root)* | public | `application` | `PagesController#home` |
| `account/` | `authenticate_user!` | `application` | Customer orders & profile |
| `admin/` | `admin_or_above?` | `admin` | `admin/dashboard` |
| `delivery/` | `admin_or_above?` | `admin` | `delivery/orders` |
| `super_admin/` | `super_admin?` | `admin` | `super_admin/employees` |

Delivery admins (`admin? && kind_delivery?`) are automatically redirected from `admin/` to `delivery/` by `Admin::BaseController#redirect_delivery_admin!`. They only see orders assigned to them (enforced via `OrderPolicy::Scope`).

### User roles & admin kinds

`User` has a `role` enum (`customer / admin / super_admin`) and an `admin_kind` enum (`ops / delivery`, nullable). Key helpers: `admin_or_above?`, `delivery_admin?`, `super_admin?`, `developer?`. The `developer` boolean flag gates experimental features.

### Pricing

`selling_price = base_cost * (1 + markup_percentage / 100)`, calculated via `before_save :calculate_selling_price` on `Product`. The global default markup lives in `GlobalSetting["global_markup_percentage"]` (default 250%). Tax rate is `GlobalSetting["tax_rate"]` (default 8.25%). `PriceCalculator.call(base_cost:, markup_percentage:)` is the standalone service for one-off calculations.

### Order lifecycle

Status flow: `pending → paid → scheduled_for_delivery → out_for_delivery → delivered` (or `canceled` / `refunded`). Valid transitions are enforced by `Order::STATUS_TRANSITIONS`. Stock is decremented **only** after the Stripe `payment_intent.succeeded` webhook (`WebhooksController`). External/layaway orders (`payment_method: :external | :layaway`) bypass Stripe and are paid immediately via `Orders::ExternalCheckout`.

`Order` columns of note:
- `shipping_address` — JSONB hash with keys `full_name, street_address, city, state, zip_code`
- `source` enum — `web_customer / admin_manual / phone / in_store`
- `payment_method` enum — `stripe / external / layaway`
- `guest_name/email/phone` — raw columns for guest overrides; `customer_name/email/phone` are helpers that fall back to `user.*`
- `order_items.unit_cost` + `markup_percentage` — snapshot pricing at time of sale

### Service objects

All live under `app/services/`. Convention: class method `.call(...)`, returns a `Result` struct with `.success?` / `.error`.

Key services:
- `ShippingCalculator.call(cart:, zip_code:)` — looks up `DeliveryZone` by ZIP (PostgreSQL array: `"? = ANY(zip_codes)"`)
- `OrderCreator.call(cart:, checkout_params:, user:)` — standard Stripe checkout path
- `Orders::AdminCreate.call(params:, admin:)` — manual order entry; snapshots cost/markup; optionally creates a guest `User`
- `Orders::ExternalCheckout.call(cart:, checkout_params:, user:, payment_reference:)` — bypasses Stripe, sets `status: :paid` immediately
- `Orders::AssignDelivery.call(order:, assigned_to:, assigned_by:)` — assigns delivery person, creates `delivery_event`, sends mailer
- `RevenueAnalyticsQuery.call(period:)` — returns sales/cost/profit/margin + chart arrays

### Authorization

Pundit is the authorization layer (`include Pundit::Authorization` in `ApplicationController`). `ApplicationPolicy` defaults: `index?/show?/create?/update?` → `admin_or_above?`, `destroy?` → `super_admin?`. Scopes control record-level visibility (delivery admins see only their assigned orders).

### Frontend

- **Tailwind CSS v4** (CSS-first, no `tailwind.config.js`). Config lives in `app/assets/tailwind/application.css` with `@import "tailwindcss"` and `@theme` custom properties. The warm palette (`--color-warm-*`) and amber (`bg-amber-700`, `focus:ring-amber-500`) are the admin UI's primary colors.
- **Stimulus** via importmap. All controllers in `app/javascript/controllers/` are auto-loaded. Notable controllers: `save-button` (inline form save with loading/success states), `drawer` (mobile slide-in nav), `confirm-modal` (delete confirmation `<dialog>`), `revenue-chart` (Chart.js wrapper), `admin-order` (manual order form with product/user data embedded as JSON).
- **Turbo** — admin inline-save rows respond with `head :no_content` on success / `head :unprocessable_content` on failure (no full page reload). Turbo cache flicker is suppressed via `body[data-turbo-preview]` CSS rule.
- **No Node / webpack** — JS is served via importmap. Chart.js is pinned via CDN in `importmap.rb`.

### Pagination

`include Pagy::Method` is in `ApplicationController`. Usage: `@pagy, @records = pagy(:offset, scope)`. Default page size: 24 (`Pagy.options[:limit]`). Render with `@pagy.series_nav` in views.

### Email

`letter_opener` in development (no SMTP needed). `OrderMailer` covers: `confirmation`, `admin_notification`, `delivery_assigned`, `out_for_delivery`, `order_delivered`, `order_delivered_customer`. `mailer_observer.rb` logs every delivery to `EmailLog`. Mailer specs use `ActiveJob::Base.queue_adapter = :test`.

### Admin layout nav

The `admin` layout has a horizontal-scroll top nav on mobile and a sidebar is irrelevant (it's top nav). On `md+` screens the top nav displays all links. On small screens a hamburger button opens the `drawer` controller slide-in panel.

### Seeds / dev credentials

```
admin@killeenfurniture.com / changeme123!    (super_admin)
delivery@killeenfurniture.com / changeme123! (delivery admin)
```
Dev quick-login buttons are rendered on the Devise sign-in page when `Rails.env.development?`.

### Environment variables (copy `.env.example` → `.env`)

`STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `AWS_*` (ActiveStorage S3), `ADMIN_EMAIL`, `SENDGRID_API_KEY`, `ANTHROPIC_API_KEY` (Claude Vision for screenshot product import).

### Key gotchas

- **ERB inside Ruby strings**: Never write `class: "... <%= expr %>"` — embedding `<%= %>` inside a string literal passed as a Ruby argument breaks Erubi parsing. Use the array-join pattern instead: `class: ["base-classes", ("conditional-class" if cond)].compact.join(" ")`.
- **`%>>` in ERB**: `<option value="x" <%= "selected" if cond %>>` — the `%>>` sequence is fragile. Use Rails `select_tag` / `options_for_select` instead of raw `<option>` tags with inline `<%= %>`.
- **Devise email**: `reconfirmable = false` in `config/initializers/devise.rb`, so `user.update(email: new_email)` updates the email column directly with no confirmation step. `confirmation_required?` is overridden to return `Rails.env.production?` only.
- **Stock decrement**: Never decrement stock in the order creation path. It must happen inside `WebhooksController#handle_payment_success` for Stripe orders, or inside `Orders::ExternalCheckout` for non-Stripe orders.
- **FK constraints on User destroy**: `layaway_payments.collected_by_id` is `NOT NULL` with no `dependent:` declared on `User` — destroying a user who has layaway payment records will raise `ActiveRecord::InvalidForeignKey`. Rescue it with a friendly message rather than cascading deletes.
- **Placeholder emails**: Employees created without an email get a synthetic `employee-<hex>@no-email.local` address. The index view detects this suffix and renders the field blank. The update action regenerates a placeholder if the field is submitted empty.
- **`button_to` in tables**: Use `form: { class: "contents" }` on `button_to` calls inside table cells to avoid breaking table layout.
