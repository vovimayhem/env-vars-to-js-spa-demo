# Stage 1: development-base ====================================================
# This stage will contain the minimal dependencies for the rest of the images
# used to build the project:

# Use the official node LTS release (on Debian "bullseye") image as base:
FROM node:lts-bullseye AS development-base

# Install the app build system dependency packages - we won't remove the apt
# lists from this point onward:
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    git

# Receive the developer user's UID and USER:
ARG DEVELOPER_UID=1000
ARG DEVELOPER_USERNAME=you

# Replicate the developer user's group & user in the development image - UNLESS
# they actually exist:
RUN getent group ${DEVELOPER_UID} || addgroup --gid ${DEVELOPER_UID} ${DEVELOPER_USERNAME}
RUN getent passwd ${DEVELOPER_UID} || useradd -r -m -u ${DEVELOPER_UID} --gid ${DEVELOPER_UID} \
    --shell /bin/bash -c "Developer User,,," ${DEVELOPER_USERNAME}

# Ensure the developer user's home directory and app path are owned by him/her:
# (A workaround to a side effect of setting WORKDIR before creating the user)
RUN userhome=$(getent passwd ${DEVELOPER_UID} | awk -F: '{print $6}') \
 && chown -R ${DEVELOPER_UID}:${DEVELOPER_UID} $userhome \
 && mkdir -p /workspaces/env-vars-to-js-spa-demo \
 && chown -R ${DEVELOPER_UID}:${DEVELOPER_UID} /workspaces/env-vars-to-js-spa-demo

# Add the app's "bin/" directory to PATH:
ENV PATH=/workspaces/env-vars-to-js-spa-demo/node_modules/.bin:$PATH

# Set the app path as the working directory:
WORKDIR /workspaces/env-vars-to-js-spa-demo

# Change to the developer user:
USER ${DEVELOPER_UID}

# Stage 2: Testing =============================================================
# In this stage we'll complete an image with the minimal dependencies required
# to run the tests in a continuous integration environment.
FROM development-base AS testing

# Receive the developer user ID argument again - ARGS won't persist between
# stages on non-buildkit builds:
ARG DEVELOPER_UID=1000

# Copy the project's dependency lists:
COPY --chown=${DEVELOPER_UID} package.json yarn.lock /workspaces/env-vars-to-js-spa-demo/

# Install the project node dependency packages, skipping "development" packages
# if possible:
RUN yarn install

# Stage 3: Development =========================================================
# In this stage we'll add the packages, libraries and tools required in our
# day-to-day development process.

# Use the "development-base" stage as base:
FROM development-base AS development

# Change to root user to install the development packages:
USER root

# Install sudo, along with any other tool required at development phase:
RUN apt-get install -y --no-install-recommends \
  # Adding bash autocompletion as git without autocomplete is a pain...
  bash-completion \
  # gpg & gpgconf is used to get Git Commit GPG Signatures working inside the
  # VSCode devcontainer:
  gpg \
  openssh-client \
  # Para esperar a que el servicio de minio (u otros) esté disponible:
  netcat \
  # /proc file system utilities: (watch, ps):
  procps \
  # Vim will be used to edit files when inside the container (git, etc):
  vim \
  # Sudo will be used to install/configure system stuff if needed during dev:
  sudo

# Receive the developer user ID argument again - ARGS won't persist between
# stages on non-buildkit builds:
ARG DEVELOPER_UID=1000

# Add the developer user to the sudoers list:
RUN DEVELOPER_USERNAME=$(getent passwd ${DEVELOPER_UID} | awk -F: '{print $1}') \
 && echo "${DEVELOPER_USERNAME} ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${DEVELOPER_USERNAME}"

# Persist the bash history between runs
# - See https://code.visualstudio.com/docs/remote/containers-advanced#_persist-bash-history-between-runs
RUN DEVELOPER_USERNAME=$(getent passwd ${DEVELOPER_UID} | awk -F: '{print $1}') \
 && SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/command-history/.bash_history" \
 && mkdir /command-history \
 && touch /command-history/.bash_history \
 && chown -R ${DEVELOPER_USERNAME} /command-history \
 && echo $SNIPPET >> "/home/${DEVELOPER_USERNAME}/.bashrc"

# Create the extensions directories:
RUN DEVELOPER_USERNAME=$(getent passwd ${DEVELOPER_UID} | awk -F: '{print $1}') \
 && mkdir -p \
  /home/${DEVELOPER_USERNAME}/.vscode-server/extensions \
  /home/${DEVELOPER_USERNAME}/.vscode-server-insiders/extensions \
 && chown -R ${DEVELOPER_USERNAME} \
  /home/${DEVELOPER_USERNAME}/.vscode-server \
  /home/${DEVELOPER_USERNAME}/.vscode-server-insiders

# Change back to the developer user:
USER ${DEVELOPER_UID}

# Install the full node package list:
RUN yarn install

# Stage 4: Builder =============================================================
# In this stage we'll add the rest of the code, compile assets, and perform a
# cleanup for the releasable image.
FROM testing AS builder

# Receive the developer user ID argument again - ARGS won't persist between
# stages on non-buildkit builds:
ARG DEVELOPER_UID=1000