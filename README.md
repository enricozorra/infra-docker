# infra-docker

Docker image definitions for production and local development use across my projects.

Images are automatically built and published to the GitHub Container Registry (`ghcr.io`) on every tagged release.

## Images

### `ghcr.io/<owner>/php-symfony:<php-version>`

PHP-FPM image tailored for Symfony projects. Includes Composer, Node.js, and common PHP extensions (pgsql, gd, intl, xsl, zip, opcache, exif).

| Tag | Description |
|-----|-------------|
| `8.2` | Latest release for PHP 8.2 |
| `8.2-1.0.0` | Specific versioned release |

## Usage

### Production (`docker-compose.yml`)

```yaml
services:
  php:
    image: ghcr.io/<owner>/php-symfony:8.2
    environment:
      PHP_FPM_PM_MAX_CHILDREN: 40      # optional, default: 20
      PHP_FPM_PM_START_SERVERS: 10     # optional, default: 5
      PHP_FPM_PM_MIN_SPARE_SERVERS: 5  # optional, default: 3
      PHP_FPM_PM_MAX_SPARE_SERVERS: 20 # optional, default: 10
      PHP_FPM_PM_MAX_REQUESTS: 500     # optional, default: 500
```

Default FPM values are calibrated for a **2GB RAM** server (~50MB per process).

### Local development (build from source)

```sh
docker build --target dev -t php-symfony:8.2-dev php/8.2
```

## Releasing

```sh
git tag v1.0.0
git push origin v1.0.0
```

The CI workflow will build and push all images to GHCR automatically.
