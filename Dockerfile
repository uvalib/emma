# Dockerfile
#
# The mix of packages to add are based on the needs of various gems:
# @see https://github.com/exAspArk/docker-alpine-ruby/blob/master/Dockerfile
#
#   GEM             NEEDS PACKAGES
#   -------         ---------------
#   oj              make gcc libc-dev
#   puma            make gcc libc-dev
#   byebug          make gcc libc-dev
#   nokogiri        make libxml2 libxslt-dev g++
#   rb-readline     ncurses
#   ffi             libffi-dev
#   mysql2          mysql-dev
#   unf_ext         g++
#   tiny_tds        freetds-dev
#   dependencies    ca-certificates git

FROM ruby:2.5.3-alpine
RUN apk --no-cache add \
    ruby ruby-dev ruby-bundler ruby-json ruby-irb ruby-rake ruby-bigdecimal \
    bash \
    g++ \
    gcc \
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

# To avoid installing documentation for gems.
COPY gemrc $HOME/.gemrc

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
