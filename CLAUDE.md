# Project context

Docker image definitions for production and local use. Images are pushed to GHCR via GitHub Actions on git tag push.

## Structure

- `php/<version>/Dockerfile` — multi-stage build: `base` → `dev` / `prod`
- `.github/workflows/build.yml` — builds and pushes only the `prod` stage on tag push

## Conventions

- Image naming: `ghcr.io/<owner>/php-symfony:<php-version>`
- Versioning: git tags (`v1.0.0`) → image tags (`8.2-1.0.0` + `8.2` as latest)
- PHP-FPM config is generated at container startup via `envsubst` from a template embedded in the Dockerfile
- Dev stage is not pushed to GHCR — built locally with `--target dev`
- Adding a new PHP version: create `php/<version>/`, copy the Dockerfile, update the matrix in `build.yml`

## FPM env vars (prod defaults for 2GB RAM)

| Variable | Default |
|----------|---------|
| `PHP_FPM_PM_MAX_CHILDREN` | 20 |
| `PHP_FPM_PM_START_SERVERS` | 5 |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | 3 |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | 10 |
| `PHP_FPM_PM_MAX_REQUESTS` | 500 |
