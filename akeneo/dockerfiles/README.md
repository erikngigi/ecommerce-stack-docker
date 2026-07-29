# Akeneo 7 PHP-FPM Docker Image

A custom PHP-FPM 8.1 Docker image built for running **Akeneo PIM version 7**, with all required PHP extensions, Node.js/Yarn tooling, and Composer pre-installed.

## Overview

|                |                                           |
| -------------- | ----------------------------------------- |
| **Base image** | `php:8.1-fpm`                             |
| **Maintainer** | Eric Ngigi (`eric@ericngigi.com`)         |
| **Version**    | 1.5                                       |
| **Purpose**    | PHP-FPM environment tailored for Akeneo 7 |

## What's Included

### System Packages

The image installs the system libraries needed to compile and run the PHP extensions Akeneo depends on:

- **`sudo`** – allows the application user limited elevated access
- **`libpng-dev`, `libjpeg62-turbo-dev`, `libfreetype6-dev`, `libgd-dev`** – image processing (used by the `gd` PHP extension)
- **`libzip-dev`** – archive/zip support (`zip` extension)
- **`libxml2-dev`, `libxslt-dev`** – XML/XSLT support (`xml`, `xsl` extensions)
- **`libonig-dev`** – multibyte string support (`mbstring` extension)
- **`libssl-dev`** – SSL/TLS support
- **`libicu-dev`** – internationalization support (`intl` extension)
- **`libmagickwand-dev`** – required to build the `imagick` PECL extension
- **`libcurl4-openssl-dev`** – cURL support (`curl` extension)
- **`git`, `unzip`, `curl`, `gnupg2`, `bash`, `vim`** – general dev tooling and utilities

### Node.js & Yarn

- **Node.js 18.x (LTS)** installed via the NodeSource setup script
- **Yarn 1.22.19** installed globally via npm
- A verification step (`node -v && npm -v && yarn -v`) confirms the install during build

Akeneo's front-end asset pipeline (Webpack/Encore) requires Node and Yarn, so these are baked into the image rather than installed at runtime.

### PHP Extensions

**Installed via PECL:**

- `imagick` – ImageMagick bindings, used for advanced image manipulation
- `apcu` – in-memory object caching

**Installed via `docker-php-ext-install`:**

- `bcmath` – arbitrary precision math
- `calendar` – calendar conversion
- `curl` – HTTP client support
- `exif` – image metadata reading
- `gd` (configured with `--with-freetype --with-jpeg`) – image processing
- `gettext` – internationalization/translation
- `intl` – ICU internationalization functions
- `mbstring` – multibyte string handling
- `mysqli` – MySQL access (procedural/OOP API)
- `opcache` – PHP opcode caching for performance
- `pcntl` – process control (used by queue/CLI workers)
- `pdo_mysql` – PDO driver for MySQL
- `soap` – SOAP protocol support
- `sockets` – low-level socket support
- `xsl` – XSLT transformations
- `xml` – XML parsing
- `zip` – ZIP archive handling

These extensions match Akeneo PIM's documented system requirements for database access, caching, internationalization, and file/media handling.

### Composer

- **Composer 2.x** is installed globally to `/usr/local/bin/composer` via the official installer script
- `/usr/local/bin` is added to `PATH` (redundant with the default, but explicit)

## Non-Root User Setup

For security, the container does **not** run as root. A dedicated application user is created with configurable UID/GID:

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
   - `/home/${USER_NAME}/akeneo7` — intended location for the Akeneo application code
   - `/home/${USER_NAME}/tools`
4. Ownership of the home directory is set to the new user
5. `COMPOSER_HOME` is set to `/home/${USER_NAME}/.composer`, ensuring Composer's cache/config is stored in a writable, user-owned location
6. The image switches to this user via `USER ${USER_NAME}`
7. `WORKDIR` is set to `/home/${USER_NAME}/akeneo7`

> ⚠️ **Security note:** Passwordless `sudo` for the application user is convenient for local development but should be reconsidered for production deployments, where it expands the container's attack surface.

## Entrypoint

The container starts:

```
CMD ["php-fpm"]
```

PHP-FPM runs in the foreground, listening for FastCGI requests (typically proxied from an Nginx/Apache container in front of it).

## Building the Image

```bash
docker build \
  --build-arg USER_NAME=appuser \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) \
  -t akeneo7-php-fpm:1.5 \
  .
```

Passing your host UID/GID as build args ensures files created inside the container (e.g. via Composer/Yarn) are owned by your host user when volumes are mounted.

## Running the Container

```bash
docker run -d \
  --name akeneo7-fpm \
  -v $(pwd)/akeneo7:/home/appuser/akeneo7 \
  akeneo7-php-fpm:1.5
```

This image is designed to be used **alongside**:

- A web server (Nginx/Apache) configured to forward PHP requests to this container's port `9000`
- A MySQL/MariaDB database container
- Optionally Elasticsearch/OpenSearch (required by Akeneo PIM) and Redis

It does not include a web server itself — it's a FastCGI process manager only.

## Typical Use With Docker Compose

This image is typically one service among several in a `docker-compose.yml`, for example:

```yaml
services:
  php-fpm:
    build:
      context: .
      args:
        USER_ID: "1000"
        GROUP_ID: "1000"
    volumes:
      - ./akeneo7:/home/appuser/akeneo7
    depends_on:
      - mysql
      - elasticsearch

  nginx:
    image: nginx:stable
    ports:
      - "8080:80"
    volumes:
      - ./akeneo7:/home/appuser/akeneo7
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php-fpm

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: akeneo_pim

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.9
    environment:
      - discovery.type=single-node
```

## Notes & Recommendations

- **Node 18** is EOL-aware software; check Akeneo 7's documented Node version requirements to confirm compatibility with your target Akeneo minor release.
- **`apt-get clean && rm -rf /var/lib/apt/lists/*`** after each install step keeps image layers smaller.
- Consider pinning package versions (e.g. Composer, Yarn already pinned; PECL/apt packages are not) for fully reproducible builds.
- For production, review whether passwordless `sudo` and `vim`/dev tooling are necessary, or better suited to a separate development-only image variant.
