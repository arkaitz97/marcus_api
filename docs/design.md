# Design: configurable product configurator API

Status: accepted · Scope: `marcus_api` (the Vue admin lives in `marcus_gui`)

## Context and scope

A configurable product is sold as a set of parts, and each part offers options.
Not every combination is allowed, and some combinations change the price. The
API owns the catalogue, the compatibility and pricing rules, and the orders.

In scope: products, parts, options, pairwise restrictions, pairwise price
premiums, selection validation, price calculation, order placement with a
stored price, and status changes on an order.

Out of scope: customer accounts, payments, inventory counts beyond a boolean
`in_stock`, discounts, tax, shipping, i18n, and multi-tenant isolation.

## Goals

1. One place decides whether a selection is valid. The client renders; the API
   enforces.
2. A stored order keeps the price the customer saw at creation time, even if the
   catalogue changes later.
3. Adding a new part or option requires data, not code.
4. The HTTP contract is small enough to document in one page and to test with
   request tests.

## Non-goals

- A general rule language. Arbitrary expressions, quantities, "choose exactly
  two" constraints and per-part surcharges are not modelled.
- High write throughput. SQLite and a single Puma process are deliberate.
- Authentication and authorisation. The demo has none.

## The design

**Data model.** `Product has_many :parts`, `Part has_many :part_options`,
`PartOption` carries `name`, `price` and `in_stock`. Two join models carry the
rules:

- `PartRestriction(part_option_id, restricted_part_option_id)` means "these two
  options cannot be selected together". The pair is stored once: the model
  rejects the mirror row at creation, and a unique index on the ordered pair
  backs that up.
- `PriceRule(part_option_a_id, part_option_b_id, price_premium)` adds a premium
  when both options are in the selection. The same one-direction rule applies.

`Order` stores `customer_name`, `customer_email`, `status` and `total_price`.
`OrderLineItem` joins the order to the chosen options.

**Validation.** `validate_selection` loads the options, then reports: empty
selection, out-of-stock options, options from more than one product, and any
restriction row whose two ids are both selected. Order creation runs the same
checks and refuses the order with `422`.

**Pricing.** The total is `sum(option.price)` plus `sum(price_premium)` for every
price rule whose two options are both selected. `BigDecimal` is used for the
arithmetic and the column is `decimal(10,2)`, so the JSON carries a string such
as `"180.0"` instead of a float.

**Order creation.** Validation and pricing run before the insert. The order and
its line items are written in one transaction, with `status: pending`. If the
selection disappears between the check and the insert, the transaction rolls
back and the request returns `500`; there is no partially written order.

## Alternatives considered

**One Rails monolith with server-rendered views (Hotwire).** Less code and no
CORS. Rejected because the configurator is interactive: option choice drives a
price and a validity check on every change. A JSON API makes that interaction
explicit and lets a second client (the admin SPA, a future mobile app) reuse it.

**A single-page app with JSON:API and client-side rules.** Rejected: the rules
would be duplicated in the browser and could be bypassed by posting an order
directly. The API must stay the only authority, so the rule engine lives there.
JSON:API was also more ceremony than this contract needs; plain Rails `render
json:` keeps the payloads readable.

**A rule table with an expression DSL (`min_parts`, `excludes`, `requires`).**
That is the general solution and it is the wrong size here. Two pairwise tables
cover the domain and are readable in the admin UI. If a "one of these three"
constraint appears, the pair table is no longer enough; that is the trigger to
revisit this decision (see ADR 0001).

**PostgreSQL from the start.** Rejected for the demo: SQLite keeps setup to
`bin/rails db:setup` and the schema avoids database-specific features. The
Dockerfile and Kamal volume make the swap a `database.yml` change plus a dump.

## Cross-cutting concerns

**Security.** No authentication by design; the API is a local demo. Brakeman and
RuboCop run in CI, and a gitleaks job scans history. Strong parameters on every
controller. No secrets in the repository; `config/master.key` is ignored.

**Money.** Decimals only. Parsing happens once, in the pricing method; the order
stores the result rather than recomputing it on read.

**Data integrity.** Foreign keys on every reference, unique index on each rule
pair, `dependent: :destroy` down the catalogue tree. Deleting a product removes
its parts, options, rules and line items.

**Known limits.** The selection validator is implemented twice, in
`ProductConfigurationController` and `OrdersController`. They agree today and
the tests cover both, but a third caller should force the extraction of one
service object. Order pricing is O(number of rules matching the selection) with
one indexed query, which is fine for catalogue-sized rule sets.

**Cost.** One process, one SQLite file. No background jobs are needed for the
current scope; Solid Queue is present from the Rails template and unused.
