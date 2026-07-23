# Akeneo PHP-FPM Dockerfile

This directory contains the **custom Dockerfile** for building a PHP-FPM **8.1** image tailored for **Akeneo 7**.  
The image is optimized for Akeneo’s required PHP extensions, frontend tooling, and containerized deployment in a multi-service environment.

---

## 🧱 Base Image

- **FROM:** `php:8.1-fpm`  
- **Maintainer:** Eric Ngigi `<cloud@ericngigi.com>`  
- **Description:** PHP-FPM image for Akeneo 7  
- **Version:** 1.0  

---

## ⚙️ Key Features

- Built on **PHP 8.1-FPM** with Akeneo 7 compatibility.  
- Includes all required **PHP extensions** and system libraries.  
- Installs **Node.js (LTS)** and **Yarn** for frontend asset building.  
- Ships with **Composer** for dependency management.  
- Uses a dedicated non-root user `akeneo` for improved security.  
- Default working directory set to `/var/www/html`.  
- Exposes **port 9000** for the PHP-FPM process.

---

## 🧩 Installed PHP Extensions

**Core Extensions:**
```

bcmath, calendar, curl, exif, gd, gettext, intl, mbstring,
mysqli, opcache, pcntl, pdo_mysql, soap, sockets, xsl, xml, zip

```

**PECL Extensions:**
```

imagick, apcu

````

---

## 🧰 Installed Tools and Dependencies

- **System packages:** git, vim, bash, unzip, curl, gnupg2, mycli  
- **Node.js:** Latest LTS version  
- **Yarn:** Globally installed via npm  
- **Composer:** Installed globally and added to `$PATH`

---

## 👤 User and Permissions

A dedicated non-root user is created for Akeneo operations:

```bash
user: akeneo
group: akeneo
home: /home/akeneo
````

This ensures secure and consistent permission management across volumes and runtime environments.

---

## 🚀 Usage

### 1. Build the Docker Image

```bash
docker build -t akeneo-php-fpm:8.1 .
```

### 2. Run the Container

```bash
docker run -d --name akeneo-php -p 9000:9000 akeneo-php-fpm:8.1
```

### 3. Verify PHP-FPM

```bash
docker exec -it akeneo-php php -v
```

---

## 🧱 Directory Context

This Dockerfile is part of the larger multi-service setup that includes Nginx, MySQL, and PHP template configurations.
It’s primarily referenced by `docker-compose.yml` in the project root for the **Akeneo service** build.

---

**Author:** Eric Ngigi
**Email:** [cloud@ericngigi.com](mailto:cloud@ericngigi.com)
**Version:** 1.0
