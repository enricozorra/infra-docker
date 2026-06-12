# infra-docker

[![Build & Push](https://github.com/enricozorra/infra-docker/actions/workflows/build.yml/badge.svg)](https://github.com/enricozorra/infra-docker/actions/workflows/build.yml)

Lightweight, production-ready Docker images for PHP/Symfony projects.

Built on **Alpine**, kept deliberately minimal, and published to the GitHub
Container Registry (`ghcr.io`) on every tagged release. Each PHP version ships
two flavours from a single multi-stage build: a slim **prod** image and a
batteries-included **dev** image.

## Why

- **Minimal surface.** Only the extensions a Symfony app actually needs are
  added on top of the official PHP base — smaller images, fewer CVEs.
- **One build, two targets.** `prod` and `dev` share the same `base` stage, so
  development and production run on identical foundations.
- **Tuned for production.** OPcache and PHP-FPM come pre-configured for typical
  small-to-mid VPS sizes, overridable via environment variables.
- **Multi-platform.** Images are built for `linux/amd64` and `linux/arm64`.

## Images

### `ghcr.io/enricozorra/php-symfony`

PHP-FPM image tailored for Symfony. Available PHP versions: **8.2**, **8.5**.

| Tag              | Stage | Description                                  |
| ---------------- | ----- | -------------------------------------------- |
| `8.2`            | prod  | Latest release for PHP 8.2                   |
| `8.2-<version>`  | prod  | Specific pinned release (e.g. `8.2-1.0.0`)   |
| `8.2-dev`        | dev   | Latest dev image for PHP 8.2                 |
| `8.2-<ver>-dev`  | dev   | Specific pinned dev release                  |

The same tag scheme applies to every supported PHP version (`8.5`, `8.5-dev`, …).

### What's inside

Both stages build on the official `php:<version>-fpm-alpine` image and add:

| Component        | base (prod & dev) | dev only |
| ---------------- | :---------------: | :------: |
| Composer 2.8     | ✓                 |          |
| `pdo_pgsql`      | ✓                 |          |
| `intl`           | ✓                 |          |
| Zend OPcache     | ✓ (tuned)         |          |
| Node.js + npm    |                   | ✓        |
| Xdebug           |                   | ✓        |

> The official PHP base image already bundles the core extensions Symfony
> requires (`ctype`, `iconv`, `mbstring`, `tokenizer`, `session`, `xml`/`dom`,
> `phar`, `filter`, `openssl`, `sodium`, …). This repo only layers on what's
> missing — currently a PostgreSQL PDO driver and `intl`. Need another
> extension? See [Adding extensions](#adding-extensions).

## Usage

### Extending the images in a project

The intended workflow is a multi-stage build: compile assets and dependencies
with the `-dev` image, then ship a lean runtime from the prod image.

```dockerfile
# --- build stage: full toolchain (Composer, Node, Xdebug) ---
FROM ghcr.io/enricozorra/php-symfony:8.2-dev AS build
WORKDIR /app
COPY composer.* ./
RUN composer install --no-dev --no-scripts --prefer-dist --no-progress
COPY . .
RUN composer dump-autoload --classmap-authoritative \
    && npm ci && npm run build

# --- runtime stage: slim prod image ---
FROM ghcr.io/enricozorra/php-symfony:8.2
WORKDIR /app
COPY --from=build /app /app
```

### Production (`docker-compose.yml`)

```yaml
services:
  php:
    image: ghcr.io/enricozorra/php-symfony:8.2
    environment:
      PHP_FPM_PM_MAX_CHILDREN: 40      # optional, default: 20
      PHP_FPM_PM_START_SERVERS: 10     # optional, default: 5
      PHP_FPM_PM_MIN_SPARE_SERVERS: 5  # optional, default: 3
      PHP_FPM_PM_MAX_SPARE_SERVERS: 20 # optional, default: 10
      PHP_FPM_PM_MAX_REQUESTS: 500     # optional, default: 500
```

### Local development (build from source)

```sh
docker build --target dev -t php-symfony:8.2-dev php/8.2
```

## Configuration

### PHP-FPM tuning

The FPM pool is generated at container startup via `envsubst` from
`www.conf.template`. The defaults below are calibrated for a **2GB RAM** server
(~50MB per process); override them with environment variables.

| Variable                       | prod default | dev default |
| ------------------------------ | :----------: | :---------: |
| `PHP_FPM_PM_MAX_CHILDREN`      | 20           | 5           |
| `PHP_FPM_PM_START_SERVERS`     | 5            | 2           |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | 3            | 1           |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | 10           | 3           |
| `PHP_FPM_PM_MAX_REQUESTS`      | 500          | 0           |

### OPcache

- **prod** (`app.prod.ini`): OPcache enabled with timestamp validation **off**
  (code is immutable in the image), 256MB buffer, raised interned-strings and
  accelerated-files limits, plus a larger realpath cache — the settings Symfony
  recommends for production.
- **dev** (`app.dev.ini`): OPcache **disabled** so code changes take effect
  immediately; `display_errors` on and full error reporting.

> Symfony [preloading](https://symfony.com/doc/current/performance.html#use-the-opcache-preload)
> is intentionally left to the consuming application, since the preload file
> path is project-specific.

## Adding a new PHP version

1. Create `php/<version>/` and copy an existing Dockerfile + config files into it.
2. Update the build matrix in [`.github/workflows/build.yml`](.github/workflows/build.yml).

## Adding extensions

Core/bundled PHP extensions are installed with `docker-php-ext-install`;
third-party extensions (like Xdebug) are installed with
[PIE](https://github.com/php/pie). Add the runtime library with `apk`, the
matching `-dev` package as a temporary `.build-deps` virtual package, then drop
it after compiling to keep the image small:

```dockerfile
RUN apk add --no-cache <runtime-lib> \
    && apk add --no-cache --virtual .build-deps <dev-lib> \
    && docker-php-ext-install -j$(nproc) <extension> \
    && apk del .build-deps
```

## Releasing

Images are published automatically by CI on tag push:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The [workflow](.github/workflows/build.yml) builds the `prod` and `dev` stages
for every PHP version in the matrix and pushes them to GHCR, tagging both the
exact version (`8.2-1.0.0`) and the moving major (`8.2`).
