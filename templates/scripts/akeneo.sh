#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
AKENEO_SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

# Environmental file containing Akeneo details
source "$AKENEO_SCRIPT_DIR/akeneo.env"

# Helper shell script for printing
source "$AKENEO_SCRIPT_DIR/colors.sh"

# Define a reusable function for the Docker container
akeneo_exec() {
  docker exec -it akeneo "$@"
}

# Download and extract Akeneo archive directly inside the container
print_green "Downloading Akeneo PIM"
akeneo_exec bash -c "curl -sSL https://download.akeneo.com/pim-community-standard-v7.0-latest-icecat.tar.gz -o /tmp/akeneo.tar.gz"

print_green "Extract Akeneo PIM archive"
akeneo_exec bash -c "tar -xzf /tmp/akeneo.tar.gz -C $AKENEO_INST_DIR --strip-components=1 && rm -rf /tmp/akeneo.tar.gz"

# copy .env to .env.local
print_green "Creating Akeneo .env.local file..."
akeneo_exec bash -c "cd $AKENEO_INST_DIR && cp .env .env.local"

# create an executable akeneo console application
akeneo_exec bash -c "cd $AKENEO_INST_DIR && chmod u+x bin/console"

# append details to .env.local file
print_green "Appending details to the Akeneo .env.local file"
akeneo_exec bash -c "
    cd $AKENEO_INST_DIR &&
    sed -i 's|^APP_DATABASE_HOST=.*|APP_DATABASE_HOST=$MYSQL_AKENEO_DATABASE_HOST|' .env.local;
    sed -i 's|^APP_DATABASE_NAME=.*|APP_DATABASE_NAME=$MYSQL_AKENEO_DATABASE|' .env.local;
    sed -i 's|^APP_DATABASE_USER=.*|APP_DATABASE_USER=$MYSQL_AKENEO_USER|' .env.local;
    sed -i 's|^APP_DATABASE_PASSWORD=.*|APP_DATABASE_PASSWORD=$MYSQL_AKENEO_PASSWORD|' .env.local;
    sed -i 's|^APP_INDEX_HOSTS=.*|APP_INDEX_HOSTS=$APP_INDEX_HOSTS|' .env.local;
    sed -i 's|^AKENEO_PIM_URL=.*|AKENEO_PIM_URL=$AKENEO_PIM_URL|' .env.local;
"

# Update browserlist
print_green "Updating Browserlist for Akeneo"
akeneo_exec bash -c "cd $AKENEO_INST_DIR && yes | npx update-browserslist-db@latest"

# Initialize Akeneo Database & Fixtures (This creates and activates 'en_US')
print_blue "Initializing Akeneo Database & Locales..."
akeneo_exec bash -c "cd $AKENEO_INST_DIR && bin/console pim:installer:db --env=dev -n"

# Install akeneo
print_blue "Installing Akeneo"
akeneo_exec bash -c "cd $AKENEO_INST_DIR && chmod -R 777 /var/cache var/logs public/media"
akeneo_exec bash -c "cd $AKENEO_INST_DIR && NO_DOCKER=true make dev"

print_green "Creating User $AKENEO_USERNAME"
akeneo_exec bash -c "cd $AKENEO_INST_DIR && bin/console pim:user:create \
  $AKENEO_USERNAME \
  $AKENEO_PASSWORD \
  $AKENEO_USER_EMAIL \
  $AKENEO_FIRST_NAME \
  $AKENEO_LAST_NAME \
  $AKENEO_LOCALE --admin -n --env=dev"
