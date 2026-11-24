# 1. Model compatibility and price rules as pairwise tables

- Status: accepted
- Date: 2026-11-24
- Deciders: Arkaitz Molinuevo
- Consulted: `docs/design.md`

## Context and problem statement

A configuration is a set of part options. The business needs two rule types: some
pairs of options are incompatible, and some pairs add a price premium. The rule
set is small (tens of rows), edited by hand from an admin UI, and read on every
validation and order.

How should the API represent these rules so that the admin can maintain them
without a developer, the order path can enforce them, and the model stays honest
about what it cannot express?

## Considered options

1. Two pairwise join tables: `part_restrictions` and `price_rules`.
2. One generic `rules` table with a serialized expression or JSON condition.
3. A compatibility matrix per product (one row per option pair, with flags).

## Decision

Use two pairwise tables, each row joining two part options. A restriction row
means "these options cannot be selected together"; a price rule row adds
`price_premium` when both options are selected. Store each unordered pair once:
the model rejects a row whose mirror already exists (`inverse_*` validations) and
a unique index covers the ordered pair. Validation and pricing read the rows
that match the current selection with one indexed query each.

## Consequences

- Good: the admin UI edits plain rows; no parser, no evaluation sandbox, no
  migration when a new incompatibility is added.
- Good: the validation is a single `where(part_option_id: ids,
  restricted_part_option_id: ids)`, so the cost follows the selection, not the
  catalogue.
- Good: the data is readable in `rails console` and in a SQL client.
- Bad: the model cannot express "at most one of these three", quantities,
  per-part surcharges, or a premium that depends on three options. Those need a
  new table or a rule language, and that is the trigger to revisit this ADR.
- Bad: symmetry is enforced in application code, not by the database, because
  the unique index only covers one ordering. A direct SQL insert can create a
  mirror row.
- Neutral: the rule pair is unordered, so the admin must not care which option is
  A and which is B. The inverse validation exists to keep that promise.
