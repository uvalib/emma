# Dockerfile
#
# The mix of packages to add are based on the needs of various gems:
# @see https://github.com/exAspArk/docker-alpine-ruby/blob/master/Dockerfile
#
# For contents of a package:
# @see https://pkgs.alpinelinux.org/contents?name=PACKAGE&arch=x86_64
#
# For build-base:
# @see https://git.alpinelinux.org/aports/tree/main/build-base/APKBUILD

FROM ruby:2.5.3-alpine
RUN apk update && \
    apk upgrade && \
    apk add --update --no-cache \
    bash \
    build-base \
    g++ \
    gcc \
    gcompat \
    git \
    libc-dev \
    libffi-dev \
    libxml2 \
    libxslt-dev \
    make \
    mariadb-dev \
    nodejs \
    tzdata \
    yarn && \
    rm -rf /var/cache/apk/*

# =============================================================================
# :section: System setup
# =============================================================================

ENV USER=docker \
    GROUP=sse \
    LANG='en_US.UTF-8' \
    LC_ALL='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    TZ='America/New_York'

# Create the run user and group
RUN addgroup -g 18570 $GROUP && \
    adduser -u 1984 $USER -G $GROUP -D

# Set the timezone
RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "$TZ" > /etc/timezone

# =============================================================================
# :section: Platform setup
# =============================================================================

ENV APP_HOME=/emma \
    RAILS_ENV=production

# Define work directory.
WORKDIR $APP_HOME

# Copy the Gemfile and Gemfile.lock into the image.
ADD Gemfile Gemfile.lock ./
RUN bundle install \
        --no-cache \
        --without=['development' 'test'] \
        --retry=2 \
        --jobs=4

# Create work directory and copy the application to it.
ADD . $APP_HOME

# Generate the assets.
RUN SECRET_KEY_BASE=x rake assets:precompile

# Update permissions on the application and user home directory.
RUN chown -R $USER:$GROUP $APP_HOME /home/$USER

# =============================================================================
# :section: Launch the application
# =============================================================================

# Set the user for the process.
USER $USER:$GROUP

# Define port and startup script.
EXPOSE 8080
CMD bin/docker
