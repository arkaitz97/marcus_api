# Security policy

## Supported versions

This is a demo repository. Only the `main` branch receives fixes.

## Reporting a vulnerability

Do not open a public issue for a security problem. Use GitHub private
vulnerability reporting:

1. Go to the repository's **Security** tab.
2. Select **Advisories** and then **Report a vulnerability**.
3. Describe the issue, the affected endpoint or file, and the steps to reproduce.

You can expect an acknowledgement within seven days. If the report is valid, the
fix and the advisory are published together.

## Scope notes

- The API has no authentication and is not intended for public deployment as-is.
- `config/master.key` must never be committed. The file is ignored by git and by
  the Docker build context.
- CI scans the history with gitleaks and runs Brakeman on every push.
