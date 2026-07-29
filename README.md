# Magento Storefront with Akeneo PIM Integration.

## 1. Introduction

This project runs Magento 2 and Akeneo PIM 7 side by side using Docker rather than installing either platform directly on the host machine. This decision was driven by three main problems that come up repeatedly when running both platforms natively:

- **Deployment speed.** Docker Compose lets the entire stack — application containers, databases, and search engines — be brought up or torn down with a single command, instead of manually provisioning services on a host each time.
- **Host cleanliness.** Installing PHP, Composer, MySQL/MariaDB, and search engines directly on a host machine leaves behind a mix of system packages, config files, and services that are hard to fully clean up or reproduce elsewhere. Containerizing each service keeps the host machine free of this clutter.
- **Conflicting PHP versions and upgrade cadence.** Magento and Akeneo require different, and sometimes incompatible, PHP versions and dependency stacks. Magento in particular releases new versions on a regular cadence, each with its own supported PHP/database/search-engine matrix. Running both natively on the same host would mean constantly juggling PHP version managers and risking one platform's upgrade breaking the other. Containers isolate each platform's runtime completely, so each can be upgraded independently.

---

## 2. Requirements

### 2.1 Host Requirements

| Requirement                                      | Purpose                                                                                                |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| Docker Engine + Docker Compose v2                | Runs and orchestrates all containers defined in `docker-compose.yml`                                   |
| Nginx (installed on the host, not containerized) | Reverse-proxies HTTPS traffic into each service's published PHP-FPM port                               |
| TLS certificates per virtual host                | Referenced by each nginx vhost (e.g. Let's Encrypt certs under `/etc/letsencrypt/live/`)               |
| A populated root `.env` file                     | Supplies database credentials consumed by `docker-compose.yml` (see [Section 4](#4-service-breakdown)) |

### 2.2 Magento Requirements

The versions actually shipped in this stack's `docker-compose.yml` are:

| Component     | Required Version | Version in this stack                                    |
| ------------- | ---------------- | -------------------------------------------------------- |
| Composer      | 2.10             | Composer **2.10** ✅ matches                             |
| Search engine | OpenSearch **3** | OpenSearch **3** ✅ matches                              |
| PHP           | 8.4              | Provided by the custom `ghcr.io/erikngigi/magento` image |
| Database      | MariaDB **11.4** | MariaDB **11.4** ✅ matches                              |

Magento's database and search-engine versions in this stack line up exactly with the official Magento 2.4.9 requirements.

<!-- > ⚠️ **Version alignment note:** MariaDB 11.4 and OpenSearch 3.x are the officially supported stack for **Magento 2.4.9** (which requires PHP 8.4/8.5). If this project is instead targeting **Magento 2.4.6**, note that 2.4.6 is officially certified against MariaDB 10.6 (LTS), OpenSearch 2.x, and PHP 8.1–8.2 — not MariaDB 11.4/OpenSearch 3. Confirm the intended Magento version and PHP version built into the image, and adjust either the Magento version or the database/search-engine versions so they match Adobe's official compatibility matrix before deploying. -->

### 2.3 Akeneo Requirements

Akeneo PIM **7.0**'s officially documented system requirements are:

| Component     | Required Version        | Version in this stack                                   |
| ------------- | ----------------------- | ------------------------------------------------------- |
| Composer      | 2.10                    | Composer **2.10** ✅ matches                            |
| PHP           | 8.1                     | Provided by the custom `ghcr.io/erikngigi/akeneo` image |
| Database      | MySQL ≥ 8.0.30, < 8.1.0 | MySQL **8.0.30** ✅ matches                             |
| Search engine | Elasticsearch 8.4.2     | Elasticsearch **8.4.2** ✅ matches                      |

Akeneo's database and search-engine versions in this stack line up exactly with the official Akeneo 7.0 requirements.

---

## 3. GitHub Workflow for Image Building

Both service images (`ghcr.io/erikngigi/magento` and `ghcr.io/erikngigi/akeneo`) are built and published via a GitHub Actions workflow rather than being built locally on each machine that runs the stack.

> 📄 Detailed documentation for each image's `Dockerfile` — base image, installed PHP extensions, build arguments, and build steps — already exists alongside each Dockerfile:
>
> - **Magento image documentation:** _link to [`magento/dockerfiles/README.md`](./magento/dockerfiles/README.md)
> - **Akeneo image documentation:** _link to [`akeneo/dockerfiles/README.md`](./akeneo/dockerfiles/README.md)
>
> _Workflow file reference / link to be added here once finalized._

---

## 4. Service Breakdown

Derived directly from `docker-compose.yml`.

### 4.1 Magento Service Breakdown

| Container            | Image                              | Depends On                         | Ports (host:container) | Secrets / Credentials                                                                                         |
| -------------------- | ---------------------------------- | ---------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| `magento`            | `ghcr.io/erikngigi/magento:latest` | `magento-db`, `magento-opensearch` | `9000:9000`            | None directly (config/PHP files mounted read-only; DB credentials consumed by `magento-db`)                   |
| `magento-db`         | `mariadb:11.4`                     | —                                  | `3308:3306`            | `MAGENTO_DB_ROOT_PASSWORD`, `MAGENTO_DATABASE`, `MAGENTO_USER`, `MAGENTO_DB_USER_PASSWORD` (from root `.env`) |
| `magento-opensearch` | `opensearchproject/opensearch:3`   | —                                  | `9250:9200`            | None (security plugin explicitly disabled: `DISABLE_SECURITY_PLUGIN=true`)                                    |

Additional Magento notes:

- `hostname` / `container_name`: `magento`; `restart: unless-stopped`; `tty: true`
- Volumes: application source (`./src/magento`), diagnostics `info.php`, and the three PHP/PHP-FPM config files, all mounted `ro` except the source code
- `magento-opensearch` runs single-node with a fixed JVM heap (`-Xms512m -Xmx512m`)

### 4.2 Akeneo Service Breakdown

| Container       | Image                             | Depends On  | Ports (host:container) | Secrets / Credentials                                                                                     |
| --------------- | --------------------------------- | ----------- | ---------------------- | --------------------------------------------------------------------------------------------------------- |
| `akeneo`        | `ghcr.io/erikngigi/akeneo:latest` | `akeneo-db` | `9050:9050`            | None directly (config/PHP files mounted read-only; DB credentials consumed by `akeneo-db`)                |
| `akeneo-db`     | `mysql:8.0.30`                    | —           | `3307:3306`            | `AKENEO_DB_ROOT_PASSWORD`, `AKENEO_DATABASE`, `AKENEO_USER`, `AKENEO_DB_USER_PASSWORD` (from root `.env`) |
| `elasticsearch` | `elasticsearch:8.4.2`             | `akeneo-db` | `9100:9200`            | None (custom `elasticsearch.yml`/`jvm.options` mounted, no auth/security configured)                      |

Additional Akeneo notes:

- `hostname` / `container_name`: `akeneo`; `restart: unless-stopped`; `tty: true`
- Volumes: application source (`./src/akeneo`), diagnostics `info.php`, and the three PHP/PHP-FPM config files, all mounted `ro` except the source code
- `akeneo-db` additionally mounts a custom `mysql/settings/my.cnf`

### 4.3 Shared Networks & Volumes

| Resource                  | Type           | Name                                              |
| ------------------------- | -------------- | ------------------------------------------------- |
| `ecommerce-network`       | bridge network | Shared by all six containers across both services |
| `magento-db-data`         | named volume   | `magento-mariadb-volume`                          |
| `magento-opensearch-data` | named volume   | `magento-opensearch-volume`                       |
| `akeneo-db-data`          | named volume   | `akeneo-mysql-db`                                 |
| `akeneo-es-data`          | named volume   | `akeneo-elasticsearch-volume`                     |

---

## 5. PHP and PHP-FPM Configurations

Each service mounts its own independent `php.ini`, `www.conf`, and `zz-docker.conf` — configuration is **not** shared between Magento and Akeneo, and the values diverge in several places to suit each platform's workload.

### 5.1 Magento PHP and PHP-FPM Configuration

**`php.ini-development` — key directives:**

| Directive                       | Value            | Why                                                                                                                        |
| ------------------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `memory_limit`                  | `2G`             | Magento CLI operations (`setup:di:compile`, `indexer:reindex`, static content deploy) routinely exceed PHP's default limit |
| `max_execution_time`            | `18000` (5 hrs)  | Long-running CLI installs/reindexes must not be killed by a script timeout                                                 |
| `max_input_time`                | `60`             | Time allowed to parse large incoming requests                                                                              |
| `max_input_vars`                | `10000`          | Magento's admin grids/forms submit very large field counts                                                                 |
| `post_max_size`                 | `64M`            | Larger admin form submissions/imports                                                                                      |
| `upload_max_filesize`           | `64M`            | Larger file uploads (product images, import CSVs)                                                                          |
| `realpath_cache_size`           | `10M`            | Reduces filesystem `stat()` overhead across Magento's large module tree                                                    |
| `realpath_cache_ttl`            | `7200`           | Caches path resolutions for 2 hours                                                                                        |
| `date.timezone`                 | `Africa/Nairobi` | Matches deployment locale                                                                                                  |
| `zlib.output_compression`       | `Off`            | Output compression left to nginx/upstream instead of PHP                                                                   |
| `error_reporting`               | `E_ALL`          | Full error visibility (dev environment)                                                                                    |
| `display_errors`                | `On`             | Errors render in browser/CLI output — should be `Off` in a production `php.ini`                                            |
| `short_open_tag`                | `Off`            | Magento code uses full `<?php` tags only                                                                                   |
| `opcache.enable`                | `1` (explicit)   | OPcache forced on                                                                                                          |
| `opcache.memory_consumption`    | `512` (MB)       | Sized for Magento's large compiled codebase                                                                                |
| `opcache.max_accelerated_files` | `60000`          | Exceeds PHP's default (10,000) file count once vendor/generated code is included                                           |
| `opcache.validate_timestamps`   | `1` (explicit)   | Recompiles changed files automatically — correct for a dev environment with live-edited, bind-mounted source               |

**`www.conf` (PHP-FPM pool):**

| Directive                       | Value     |
| ------------------------------- | --------- |
| `user` / `group`                | `magento` |
| `listen`                        | `9000`    |
| `listen.owner` / `listen.group` | `magento` |
| `pm`                            | `dynamic` |
| `pm.max_children`               | `5`       |
| `pm.start_servers`              | `2`       |
| `pm.min_spare_servers`          | `1`       |
| `pm.max_spare_servers`          | `3`       |
| `pm.status_path`                | not set   |

**`zz-docker.conf`:**

```ini
[global]
daemonize = no

; the [www] ini section below is for backwards compatibility and will be removed in 8.6+
[www]
listen = 9000
```

### 5.2 Akeneo PHP and PHP-FPM Configuration

**`php.ini-development` — key directives:**

| Directive                                    | Value                                 | Why                                                                               |
| -------------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------------- |
| `memory_limit`                               | `2G`                                  | Same rationale as Magento — large batch operations (imports, exports, reindexing) |
| `max_execution_time`                         | `180` (3 min)                         | Akeneo's requests are shorter-lived than Magento's CLI operations                 |
| `max_input_time`                             | `60`                                  | Same as Magento                                                                   |
| `max_input_vars`                             | default (`1000`)                      | Not customized                                                                    |
| `post_max_size`                              | `100M`                                | Larger POST payloads than Magento (e.g. product asset imports)                    |
| `upload_max_filesize`                        | `100M`                                | Larger file uploads                                                               |
| `realpath_cache_size` / `realpath_cache_ttl` | default                               | Not customized                                                                    |
| `date.timezone`                              | `UTC`                                 | Different reference timezone than Magento                                         |
| `zlib.output_compression`                    | `On`                                  | Output compressed at the PHP level                                                |
| `error_reporting`                            | `E_ALL`                               | Standard `php.ini-development` default                                            |
| `display_errors`                             | `On`                                  | Standard `php.ini-development` default                                            |
| `short_open_tag`                             | `Off`                                 | Same as Magento                                                                   |
| `opcache.enable`                             | commented (extension default applies) | Not explicitly forced on                                                          |
| `opcache.enable_cli`                         | `1` (explicit)                        | Enables OPcache for Akeneo's console/CLI commands                                 |
| `opcache.memory_consumption`                 | `512` (MB)                            | Same as Magento                                                                   |
| `opcache.max_accelerated_files`              | `60000`                               | Same as Magento                                                                   |
| `opcache.validate_timestamps`                | commented (extension default applies) | Not explicitly forced                                                             |

**`www.conf` (PHP-FPM pool):**

| Directive                       | Value                                           |
| ------------------------------- | ----------------------------------------------- |
| `user` / `group`                | `akeneo`                                        |
| `listen`                        | `9050`                                          |
| `listen.owner` / `listen.group` | `akeneo`                                        |
| `pm`                            | `dynamic`                                       |
| `pm.max_children`               | `5`                                             |
| `pm.start_servers`              | `2`                                             |
| `pm.min_spare_servers`          | `1`                                             |
| `pm.max_spare_servers`          | `3`                                             |
| `pm.status_path`                | `/status` (explicitly enabled — unlike Magento) |

**`zz-docker.conf`:**

```ini
[global]
daemonize = no

[www]
listen = 9050
```

**Key difference from Magento:** Akeneo's PHP-FPM pool listens on `9050` end-to-end (matching the compose port mapping), while Magento uses the PHP-FPM default of `9000`. Akeneo also explicitly exposes the FPM status page path (`pm.status_path = /status`) at the pool level, whereas Magento's status endpoint is instead defined directly in its nginx vhost.
