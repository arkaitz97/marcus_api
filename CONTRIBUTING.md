# Contributing

## Before you open a pull request

1. Keep the change small and focused. One concern per pull request.
2. Add or update a request test for any behaviour change. The review checks the
   test name: it must state the behaviour, not the method.
3. Run the full local gate:

   ```bash
   bin/rubocop
   bin/brakeman --no-pager
   bin/rails db:test:prepare test
   ```

4. Use a conventional commit subject (`feat:`, `fix:`, `test:`, `docs:`,
   `chore:`). Explain the reason in the body when the subject cannot carry it.

## Review expectations

- A pull request without a test for new behaviour is not ready for review.
- Prefer guard clauses over nested conditionals, and one term per concept.
- A reviewer may ask for a smaller diff. Splitting is cheaper than reviewing a
  mixed change.
- Do not commit secrets, `.env` files or `config/master.key`. CI runs gitleaks on
  the full history.

## Local setup

See the README. `bin/rails db:setup` creates the development database and seeds
the demo catalogue.
