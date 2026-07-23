#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
MAGENTO_SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

# source the file with the magento details
source "$MAGENTO_SCRIPT_DIR/magento.env"

# Helper shell script for printing
source "$MAGENTO_SCRIPT_DIR/colors.sh"

# Define a reusable function for the Docker container magento
magento_exec() {
	docker exec -it magento-php-fpm "$@"
}

# Setup composer details for Magento repository
magento_exec bash -c "
cd $MAGENTO_INST_DIR && \
php bin/magento akeneo_connector:import --code=attribute,option,family,category,product
"
