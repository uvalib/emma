# config/initializers/_extensions.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions to classes that need to be established as soon as possible during
# initialization.

# =============================================================================
# Bookshare API properties
# =============================================================================

# Bookshare API key.
#
# This does not have a default and *must* be provided through the environment.
#
# @type [String, nil]
#
BOOKSHARE_API_KEY = ENV.fetch('BOOKSHARE_API_KEY', nil).freeze

# Current Bookshare API version.
#
# @type [String]
#
BOOKSHARE_API_VERSION = ENV.fetch('BOOKSHARE_API_VERSION', 'v2').freeze

# Base Bookshare API request path.
#
# @type [String]
#
BOOKSHARE_BASE_URL =
  ENV.fetch('BOOKSHARE_BASE_URL', 'https://api.bookshare.org')
    .strip
    .sub(%r{^(http:)?//}, 'https://')
    .sub(%r{/+$}, '')
    .sub(%r{(/v.+)?$}) { $1 || "/#{BOOKSHARE_API_VERSION}" }
    .freeze

# Base Bookshare authentication service path.
#
# @type [String]
#
BOOKSHARE_AUTH_URL =
  ENV.fetch('BOOKSHARE_AUTH_URL', 'https://auth.bookshare.org')
    .strip
    .sub(%r{^(http:)?//}, 'https://')
    .sub(%r{/+$}, '')
    .freeze

# Users with pre-generated OAuth tokens for development purposes.
#
# The environment variable should be in a format acceptable to #json_parse
# (either JSON or a rendering of a Ruby hash).
#
# @type [String, nil]
#
# @see OmniAuth::Strategies::Bookshare#stored_auth
#
BOOKSHARE_TEST_USERS = ENV.fetch('BOOKSHARE_TEST_USERS', nil).freeze

# =============================================================================
# EMMA Unified Search API properties
# =============================================================================

# Current EMMA Unified Search API version.
#
# This is informational only; search API URLs do not include it.
#
# @type [String]
#
SEARCH_API_VERSION = ENV.fetch('SEARCH_API_VERSION', '0.0.2').freeze

# Base EMMA Unified Search API request path.
#
# @type [String]
#
SEARCH_BASE_URL =
  ENV.fetch('SEARCH_BASE_URL','https://api.staging.bookshareunifiedsearch.org')
    .strip
    .sub(%r{^(http:)?//}, 'https://')
    .sub(%r{/+$}, '')
    .freeze

# =============================================================================
# Operational properties
# =============================================================================

# Temporary directory.
#
# If provided as a relative path it will be expanded to the full absolute path.
#
# @type [String]
#
TMPDIR = Dir.tmpdir.sub(%r{^([^/])}, Rails.root.join('\1').to_path).freeze

# OAuth2 providers for Devise.
#
# @type [Array<Symbol>]
#
OAUTH2_PROVIDERS = %i[bookshare].freeze

# =============================================================================
# Extensions and local definitions
# =============================================================================

require 'pp'
require Rails.root.join('lib/emma').to_path
