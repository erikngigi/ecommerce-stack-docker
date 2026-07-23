# Magento PHP-FPM Dockerfile

This directory contains the **custom Dockerfile** for building a PHP-FPM **8.3** image optimized for **Magento 2.4.7**.  
The image is designed to provide a lightweight, secure, and extensible PHP runtime for Magento deployments.

---

## 🧱 Base Image

- **FROM:** `php:8.3-fpm`  
- **Maintainer:** Eric Ngigi `<cloud@ericngigi.com>`  
- **Description:** PHP-FPM image for Magento 2.4.7  
- **Version:** 1.0  

---

## ⚙️ Key Features

- Built on **PHP 8.3-FPM** with full Magento 2.4.7 compatibility.  
- Includes all required **PHP extensions** and system libraries.  
- Preinstalled **Composer** for dependency management.  
- Uses a non-root `magento` user for secure container execution.  
- Exposes **port 9050** for PHP-FPM.  
- Optimized for use in Docker Compose environments with Nginx and MySQL.

---

## 🧩 Installed PHP Extensions

**Core Extensions:**
```

bcmath, calendar, exif, gd, gettext, intl, mbstring,
mysqli, opcache, pcntl, pdo_mysql, soap, sockets, xsl, xml, zip

```

**PECL Extensions:**
```

imagick, apcu

````

---

## 🧰 Installed Tools and Dependencies

- **System packages:** git, vim, bash, unzip, curl, gnupg2, mycli  
- **Composer:** Installed globally and available in `$PATH`  
- **ImageMagick & APCu:** Installed via PECL and enabled for performance

---

## 👤 User and Permissions

A dedicated non-root user is created for running Magento:

```bash
user: magento
group: magento
home: /home/magento
````

This setup ensures proper permission handling, especially when working with mounted volumes during development or deployment.

---

## 🚀 Usage

### 1. Build the Docker Image

```bash
docker build -t magento-php-fpm:8.3 .
```

### 2. Run the Container

```bash
docker run -d --name magento-php -p 9050:9050 magento-php-fpm:8.3
```

### 3. Verify PHP-FPM

```bash
docker exec -it magento-php php -v
```

---

## 🧱 Directory Context

This Dockerfile is used as part of the larger application stack managed through `docker-compose.yml`.
It defines the **Magento PHP-FPM service** and works alongside Nginx, MySQL, and other containers defined in the project.

---

**Author:** Eric Ngigi
**Email:** [cloud@ericngigi.com](mailto:cloud@ericngigi.com)
**Version:** 1.0
