# 2. Order lifecycle: server-assigned pending status and a stored price

- Status: accepted
- Date: 2026-11-24
- Deciders: Arkaitz Molinuevo
- Consulted: `docs/design.md`

## Context and problem statement

An order is created from a validated selection and later moves through a small
set of statuses. Two things must not depend on the client: the price the customer
agreed to, and the status an order starts in. The API also has to let the admin
change the status without letting it change the contents or the price.

How should the order record its state and its money?

## Considered options

1. A string `status` column validated against a constant list, a price calculated
   and stored at creation, and an update endpoint that accepts only the status.
2. An integer `enum` column with Rails `enum`, plus callbacks that recompute the
   price on read.
3. A state-machine gem with explicit transitions and a separate `order_events`
   audit table.

## Decision

Keep a string `status` column, defaulting to `pending` and validated by inclusion
in `pending`, `processing`, `completed`, `cancelled`
(`Order::VALID_STATUSES`). `OrdersController#create` forces `status: "pending"`
and merges the calculated `total_price` into the record, so neither value is
taken from the request. `orders#update` permits only `:status`. The price is a
`decimal(10,2)` column and is never recomputed on read.

## Consequences

- Good: a catalogue price change does not rewrite past orders. The stored total
  is the agreement.
- Good: a client cannot create an order already marked `completed`, and cannot
  change the contents or the price through the update route.
- Good: no gem, no extra table; the four statuses fit in one constant and the
  admin view lists them.
- Bad: there is no transition guard. The API accepts `cancelled` to `pending`
  because every status is valid for every update. A real fulfilment flow needs a
  transition map, and that is the trigger to move to option 3.
- Bad: there is no audit trail of who changed a status or when, beyond the
  `updated_at` timestamp.
- Neutral: line items are destroyed with the order (`dependent: :destroy`), so a
  cancelled order is still a record, but a deleted order leaves no trace.
