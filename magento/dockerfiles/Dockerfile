# Base image
FROM php:8.4-fpm

# Maintainer details
LABEL Maintainer="Eric Ngigi <cloud@ericngigi.com>"
LABEL Description="PHP-FPM using version 8.4 for Magento 2.4.8-p4"
LABEL Version="1.5"

# Define build arguments with fallbacks
ARG USER_NAME=appuser
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
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install official PHP Extension Installer helper
COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

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

# Create application user
RUN groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -u ${USER_ID} -ms /bin/bash -g ${USER_NAME} ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME} \
    && mkdir -p /home/${USER_NAME}/.config \
    && mkdir -p /home/${USER_NAME}/magento2 \
    && mkdir -p /home/${USER_NAME}/tools \
    && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# Set Composer home for magento user
ENV COMPOSER_HOME=/home/${USER_NAME}/.composer
RUN mkdir -p $COMPOSER_HOME && chown -R ${USER_NAME}:${USER_NAME} $COMPOSER_HOME

# Switch to non-root user
USER ${USER_NAME}

# Set working directory
WORKDIR /home/${USER_NAME}/magento2

# Start php-fpm
CMD ["php-fpm"]
