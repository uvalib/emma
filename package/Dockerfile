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

FROM ruby:2.6.3-alpine
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
    yarn \
    && rm -rf /var/cache/apk/*

# =============================================================================
# System setup
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
# Platform setup
# =============================================================================

ENV HOME=/home/$USER \
    APP_HOME=/emma \
    RAILS_ENV=production \
    BUNDLER_VERSION=2.1.4

# To avoid installing documentation for gems.
COPY storage/gemrc $HOME/.gemrc

# Update bundler if needed.
RUN gem list --silent --installed --exact bundler -v "$BUNDLER_VERSION" || \
    gem install bundler -v "$BUNDLER_VERSION"; \
    bundle config set no-cache true

# Install required gems.
COPY Gemfile Gemfile.lock /tmp/
WORKDIR /tmp
RUN bundle install --jobs 6 --retry 2 --without development test

# Create work directory and copy the application to it.
WORKDIR $APP_HOME
ADD . $APP_HOME

# Generate the assets.
RUN SECRET_KEY_BASE=x bundle exec rake assets:precompile

# Update permissions on the application and user home directory.
RUN chown -R $USER:$GROUP $HOME $APP_HOME

# Add the build tag.
ARG BUILD_TAG=0
RUN touch $APP_HOME/buildtag.build-$BUILD_TAG

# =============================================================================
# Launch the application
# =============================================================================

# Set the user for the process.
USER $USER:$GROUP

# Define port and startup script.
EXPOSE 8080
CMD bin/docker
