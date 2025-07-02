## Build, Lint, and Test

- No build, linting, or testing commands are defined.
- Scripts are executed directly.

## Code Style

- **Shell:**
  - Use `#!/usr/bin/env bash`.
  - Use `set -euo pipefail`.
  - Support a `--dry-run` flag for simulation.
  - Use a `run_cmd` helper for command execution.
  - Use `echo` for logging.
- **General:**
  - Follow existing conventions in the codebase.
  - Keep changes small and focused.
