# Base image
FROM php:8.1-fpm

# Maintainer details
LABEL Maintainer="Eric Ngigi <cloud@ericngigi.com>"
LABEL Description="PHP-FPM using version 8.1 for Akeneo 7"
LABEL Version="1.2"

# Define build arguments with fallbacks
ARG USER_ID=1001
ARG GROUP_ID=1001

# Install required system dependencies for PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    git \
    unzip \
    curl \
    gnupg2 \
    bash \
    mycli \
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js (LTS) and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g yarn \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN node -v && npm -v && yarn -v

# Install and enable third-party PHP extensions via PECL
RUN pecl install imagick apcu \
    && docker-php-ext-enable imagick apcu

# Install all required PHP extensions automatically
RUN install-php-extensions \
    apcu \
    bcmath \
    calendar \
    exif \
    ftp \
    gd \
    gettext \
    imagick \
    intl \
    mbstring \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    soap \
    sockets \
    xsl \
    zip

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add Composer to the PATH
ENV PATH="/usr/local/bin:$PATH"

# Create application user and give sudo access
RUN groupadd -g ${GROUP_ID} akeneo \
    && useradd -u ${USER_ID} -ms /bin/bash -g akeneo akeneo \
    && echo "akeneo ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/akeneo \
    && chmod 0440 /etc/sudoers.d/akeneo \
    && mkdir -p /home/akeneo/.config \
    && mkdir -p /home/akeneo/akeneo7 \
    && chown -R akeneo:akeneo /home/akeneo

# Set Composer home for Akeneo user
ENV COMPOSER_HOME=/home/akeneo/.composer
RUN mkdir -p $COMPOSER_HOME && chown -R akeneo:akeneo $COMPOSER_HOME

# Switch to non-root user
USER akeneo

# Set working directory
WORKDIR /home/akeneo

# Start php-fpm
CMD ["php-fpm"]
