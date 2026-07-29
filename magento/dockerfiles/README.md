# Magento 2.4.9 PHP-FPM Docker Image

A custom PHP-FPM 8.4 Docker image built for running **Magento 2.4.9**, with all required PHP extensions and Composer pre-installed via the `mlocati/php-extension-installer` helper.

## Overview

|                |                                                |
| -------------- | ---------------------------------------------- |
| **Base image** | `php:8.4-fpm`                                  |
| **Maintainer** | Eric Ngigi (`eric@ericngigi.com`)              |
| **Version**    | 1.7                                            |
| **Purpose**    | PHP-FPM environment tailored for Magento 2.4.9 |

## What's Included

### System Packages

Unlike a traditional PHP Docker setup, this image installs almost no `-dev` libraries directly — extension building is delegated to the extension installer helper (see below). Only general tooling is installed via `apt`:

- **`sudo`** – allows the application user limited elevated access
- **`git`** – version control, used by Composer for VCS package installs
- **`unzip`** – archive extraction (Composer package installs)
- **`curl`** – HTTP client, used to fetch the Composer installer
- **`gnupg2`** – GPG support for package verification
- **`bash`, `vim`** – shell and editor for interactive/dev use

### PHP Extension Installer

```dockerfile
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
```

This copies the `install-php-extensions` binary from the well-known [`mlocati/php-extension-installer`](https://github.com/mlocati/docker-php-extension-installer) image (multi-stage build, no separate build stage needed in this Dockerfile). This tool automatically resolves and installs any system `-dev` libraries an extension needs, compiles it, and enables it — which is why the manual `libpng-dev`, `libzip-dev`, etc. packages seen in older-style Dockerfiles aren't listed explicitly here.

### PHP Extensions

Installed in a single step via `install-php-extensions`:

- `apcu` – in-memory object caching
- `bcmath` – arbitrary precision math (required by Magento for pricing/tax calculations)
- `calendar` – calendar conversion
- `exif` – image metadata reading
- `ftp` – FTP client support
- `gd` – image processing (product images, thumbnails)
- `gettext` – internationalization/translation
- `imagick` – ImageMagick bindings for advanced image manipulation
- `intl` – ICU internationalization functions
- `mbstring` – multibyte string handling
- `mysqli` – MySQL access (procedural/OOP API)
- `opcache` – PHP opcode caching, critical for Magento performance
- `pcntl` – process control (used by Magento's cron and queue consumers)
- `pdo_mysql` – PDO driver for MySQL
- `soap` – SOAP protocol support (Magento web API/SOAP integrations)
- `sockets` – low-level socket support
- `xsl` – XSLT transformations
- `zip` – ZIP archive handling (module packaging, sample data, etc.)

This list matches Magento 2.4.9's documented PHP extension requirements for PHP 8.4 (note: `xml`, `dom`, `simplexml`, `curl`, `iconv`, `openssl`, `pdo`, `fileinfo`, and `filter` are typically already bundled/enabled in the `php:8.4-fpm` base image by default, so they aren't listed here).

### Composer

- **Composer 2.x** (latest available) is installed globally to `/usr/local/bin/composer` via the official installer script
- Note: this Dockerfile omits the `--2` flag used in some other variants — since Composer's installer now defaults to the latest stable 2.x release, this has the same effect
- `/usr/local/bin` is explicitly added to `PATH`

## Non-Root User Setup

The container does **not** run as root. A dedicated application user is created with configurable UID/GID:

### Build Arguments

| Argument    | Default   | Description                      |
| ----------- | --------- | -------------------------------- |
| `USER_NAME` | `appuser` | Name of the non-root user        |
| `USER_ID`   | `1001`    | UID assigned to the user         |
| `GROUP_ID`  | `1001`    | GID assigned to the user's group |

Matching these to your host user's UID/GID avoids file-permission conflicts when using bind-mounted volumes.

### What Happens

1. A group and user are created with the specified IDs
2. The user is granted **passwordless `sudo`** access (via `/etc/sudoers.d/${USER_NAME}`)
3. Home directory structure is created:
   - `/home/${USER_NAME}/.config`
   - `/home/${USER_NAME}/magento2` — intended location for the Magento application code
   - `/home/${USER_NAME}/tools`
4. Ownership of the home directory is set to the new user
5. `COMPOSER_HOME` is set to `/home/${USER_NAME}/.composer`, keeping Composer's cache/config in a writable, user-owned location
6. The image switches to this user via `USER ${USER_NAME}`
7. `WORKDIR` is set to `/home/${USER_NAME}/magento2`

> ⚠️ **Security note:** Passwordless `sudo` for the application user is convenient for local development but should be reconsidered for production, where it expands the container's attack surface.

## Entrypoint

```
CMD ["php-fpm"]
```

PHP-FPM runs in the foreground, listening for FastCGI requests (typically proxied from an Nginx/Apache/Varnish stack in front of it).

## Building the Image

```bash
docker build \
  --build-arg USER_NAME=appuser \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t magento2-php-fpm:1.7 \
  .
```

Passing your host UID/GID as build args ensures files created inside the container (e.g. via Composer) are owned by your host user when volumes are mounted.

## Running the Container

```bash
docker run -d \
  --name magento2-fpm \
  -v $(pwd)/magento2:/home/appuser/magento2 \
  magento2-php-fpm:1.7
```

This image is designed to be used **alongside**:

- A web server (Nginx, typically with Varnish in front for full-page cache) forwarding PHP requests to this container's port `9000`
- MySQL/MariaDB (Magento's primary datastore)
- OpenSearch or Elasticsearch (required for Magento catalog search)
- Redis (recommended for cache and session storage)
- RabbitMQ (recommended for async message queues)

It does not include a web server itself — it's a FastCGI process manager only.

## Typical Use With Docker Compose

```yaml
services:
  php-fpm:
    build:
      context: .
      args:
        USER_ID: "1000"
        GROUP_ID: "1000"
    volumes:
      - ./magento2:/home/appuser/magento2
    depends_on:
      - mysql
      - opensearch
      - redis

  nginx:
    image: nginx:stable
    ports:
      - "8080:80"
    volumes:
      - ./magento2:/home/appuser/magento2
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php-fpm

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: magento

  opensearch:
    image: opensearchproject/opensearch:2
    environment:
      - discovery.type=single-node
      - plugins.security.disabled=true

  redis:
    image: redis:7-alpine
```

## Notes & Recommendations

- **PHP 8.4 + Magento 2.4.9** — confirm this exact combination is listed in Adobe/Magento's official compatibility matrix for your target patch level before deploying to production.
- The `mlocati/php-extension-installer` approach keeps the Dockerfile short and automatically pulls in correct `-dev`/runtime library dependencies, but it does mean build reproducibility depends on that external image's tag (consider pinning it, e.g. `ghcr.io/mlocati/php-extension-installer:2.x.x`, instead of using the untagged/latest default shown here).
- **No Node.js/Yarn** is installed in this image — if you need to build Magento's frontend (Grunt/Webpack, RequireJS, or the newer `@magento/pwa-studio` builds), you'll need a separate build stage or container.
- **`apt-get clean && rm -rf /var/lib/apt/lists/*`** after installs keeps image layers smaller.
- For production, review whether passwordless `sudo` and `vim` are necessary, or better suited to a development-only image variant.
- Consider adding a `HEALTHCHECK` instruction (e.g. checking the PHP-FPM status page) for use in orchestrators like Docker Swarm or Kubernetes.
