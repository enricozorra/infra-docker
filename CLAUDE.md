## Codebase Navigation — MANDATORY

NEVER use grep, find, cat, ls, or Read to explore code.
NO EXCEPTIONS. Not even "just a quick check".

Use ONLY token-savior tools:
- find_symbol → locate any symbol
- get_function_source → read a function
- search_codebase → search across files
- get_change_impact → understand dependencies

# Project context

Docker image definitions for production and local use. Images are pushed to GHCR via GitHub Actions on git tag push.

## Structure

- `php/<version>/Dockerfile` — multi-stage build: `base` → `dev` / `prod`
- `.github/workflows/build.yml` — builds and pushes both the `prod` and `dev` stages on tag push
- Config files (`*.ini`, `www.conf.template`, `docker-entrypoint.sh`) live alongside the Dockerfile and are `COPY`-ed in

## Conventions

- Image naming: `ghcr.io/<owner>/php-symfony:<php-version>`
- Versioning: git tags (`v1.0.0`) → image tags (`8.2-1.0.0` + `8.2` as latest)
- PHP-FPM config is generated at container startup via `envsubst` from the `www.conf.template` file
- Both stages are pushed to GHCR: prod as `<php>` / `<php>-<ver>`, dev as `<php>-dev` / `<php>-<ver>-dev`
- Projects extend the published images: build assets with the `-dev` image, ship from the prod image (multi-stage)
- Adding a new PHP version: create `php/<version>/`, copy the Dockerfile, update the matrix in `build.yml`

## FPM env vars (prod defaults for 2GB RAM)

| Variable | Default |
|----------|---------|
| `PHP_FPM_PM_MAX_CHILDREN` | 20 |
| `PHP_FPM_PM_START_SERVERS` | 5 |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | 3 |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | 10 |
| `PHP_FPM_PM_MAX_REQUESTS` | 500 |
