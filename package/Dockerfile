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

FROM ruby:2.7.2-alpine
RUN apk upgrade && \
    apk add --no-cache \
    bash \
    build-base \
    gcompat \
    git \
    libxslt-dev \
    mariadb-dev \
    nodejs \
    tzdata \
    yarn

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
    RAILS_ENV=production

# Change to the application directory.
WORKDIR $APP_HOME

# To avoid installing documentation for gems.
ADD storage/gemrc         $HOME/.gemrc
ADD storage/bundle-config $HOME/.bundle/config

# Update bundler if needed then install required gems.
ADD Gemfile Gemfile.lock  ./
RUN bundle install

# Create work directory and copy the application to it.
ADD . $APP_HOME

# Generate the assets.
RUN SECRET_KEY_BASE=x bundle exec rake assets:precompile

# Update permissions on the application and user home directory.
RUN chown -R $USER:$GROUP $APP_HOME

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
