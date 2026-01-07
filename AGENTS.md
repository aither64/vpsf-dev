# Repository Guidelines

## Project Structure & Module Organization
- `bin/` holds helper scripts for development shells and API entrypoints (`api-run-in-shell.rb`, `build-node.sh`, `run-node.sh`, `update-node.sh`).
- `nodes/*.nix` defines individual vpsAdminOS VMs (e.g., `os1.nix`, `os2.nix`) and reuse shared settings from `base.nix`, `crashdump.nix`, and `networking.nix`.
- `vpsadmin/` contains service modules for the cluster (API, frontend, database, mailer, redis, rabbitmq, web UI) consumed by nodes.
- Root files such as `networking.nix`, `vars.sh`, and `shellhook.local.sh` configure addressing and the Nix/WORKSPACE paths expected by the helper shells. Keep secrets or host-specific overrides outside version control.

## Build, Test, and Development Commands
- Enter the vpsAdminOS dev shell with `./vpsadminos-shell`; from there use `bin/build-node.sh os1 os2` to build VM images, `bin/update-node.sh os1` to rebuild, and `bin/run-node.sh os1` to boot locally.
- Build and publish vpsAdminOS gems inside the shell with `make -j4 build-commit-gems` (or `build-amend-gems` to amend the last gem commit).
- Enter the vpsAdmin tree via `./vpsadmin-shell`; run `rake vpsadmin:gems` to build and deploy nodectl gems.
- For API work, use `./vpsadmin-api-shell` then `bin/api-run-in-shell.rb` to start the server, `bin/api-repl-in-shell.rb` for an interactive console, `bin/api-ruby-in-shell.rb path/to/script.rb` for custom scripts, and `bin/api-scheduler-in-shell.rb` to run the scheduler.

## Coding Style & Naming Conventions
- Nix modules use two-space indents, small attribute sets per line, and explicit imports at the top; keep naming consistent with existing node/service prefixes (`vpsadmin.*`, `networking.*`).
- Shell scripts are POSIX `sh`; keep them idempotent, use existing env variables (`WORKSPACE`, `NIX_PATH`), and place new helpers in `bin/`.
- Ruby helpers follow two-space indentation and minimal dependencies; prefer descriptive filenames with hyphens (e.g., `api-*.rb`).

## Testing Guidelines
- Primary validation is functional: build and boot the affected nodes with `bin/build-node.sh` + `bin/run-node.sh` after Nix changes, and ensure services start cleanly in logs.
- For API or gem updates, start the server via `bin/api-run-in-shell.rb` once to confirm boot and DB connectivity; run the scheduler locally if your change touches background jobs.
- Capture any reproducible steps or log excerpts in the MR/PR description when fixes target specific runtime issues.

## Commit & Pull Request Guidelines
- Follow the existing shortscope style: `<area>: <change>` (e.g., `vpsadmin/frontend: set varnish bind attr`). Use lowercase scopes that match touched paths or services.
- Each commit should be self-contained and buildable; avoid bundling unrelated node and API changes.
- PRs should describe the nodes/services affected, commands run for validation, and any config files that must be updated locally (e.g., `api/config/database.yml`, certificates). Add screenshots only when UI-facing changes occur.

## Security & Configuration Tips
- Do not commit real secrets or keys; keep private certs/tokens in local paths (e.g., `/private/*`) referenced by configs. The `certs/` directory is for local development material only.
- Ensure `WORKSPACE` matches your directory layout (default `/home/aither/workspace` in `vars.sh`) so helper shells find upstream repos; adjust `shellhook.local.sh` locally rather than committing machine-specific Nix paths.
