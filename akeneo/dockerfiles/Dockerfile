# Base image
FROM php:8.1-fpm

# Maintainer details
LABEL Maintainer="Eric Ngigi <cloud@ericngigi.com>"
LABEL Description="PHP-FPM using version 8.1 for Akeneo 7"
LABEL Version="1.4"

# Define build arguments with fallbacks
ARG USER_NAME=appuser
ARG USER_ID=1001
ARG GROUP_ID=1001

# Install required system dependencies for PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libxslt-dev \
    libonig-dev \
    libgd-dev \
    libssl-dev \
    libicu-dev \
    libmagickwand-dev \
    libcurl4-openssl-dev \
    git \
    unzip \
    curl \
    gnupg2 \
    bash \
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

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        bcmath \
        calendar \
        curl \
        exif \
        gd \
        gettext \
        intl \
        mbstring \
        mysqli \
        opcache \
        pcntl \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        xml \
        zip

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add Composer to the PATH
ENV PATH="/usr/local/bin:$PATH"

# Create application user and give sudo access
RUN groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -u ${USER_ID} -ms /bin/bash -g ${USER_NAME} ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME} \
    && mkdir -p /home/${USER_NAME}/.config \
    && mkdir -p /home/${USER_NAME}/akeneo7 \
    && mkdir -p /home/${USER_NAME}/tools \
    && chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# Set Composer home for Akeneo user
ENV COMPOSER_HOME=/home/${USER_NAME}/.composer
RUN mkdir -p $COMPOSER_HOME && chown -R ${USER_NAME}:${USER_NAME} $COMPOSER_HOME

# Switch to non-root user
USER ${USER_NAME}

# Set working directory
WORKDIR /home/${USER_NAME}

# Start php-fpm
CMD ["php-fpm"]
