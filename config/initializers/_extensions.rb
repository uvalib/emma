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

# Users with pre-generated OAuth tokens for development purposes.
#
# @type [Hash{String=>String}]
#
# == Usage Notes
# These exist because Bookshare has a problem with its authentication
# flow, so tokens were generated for two EMMA users which could be used
# directly (avoiding the OAuth2 flow).
#
BOOKSHARE_TEST_USERS = {
  'emmadso@bookshare.org'        => '88c28e10-b235-46fe-a929-e00b4c8df2cb',
  'emmacollection@bookshare.org' => '3d62f10e-aefc-486c-9047-4cfc1e6c0b8a',
  'emmamembership@bookshare.org' => '28171ad0-fca6-4b98-8b8d-2be88a619b58',
}.freeze

# Bookshare API key.
#
# This does not have a default and *must* be provided through the environment.
#
# @type [String]
#
BOOKSHARE_API_KEY =
  ENV.fetch('BOOKSHARE_API_KEY', nil).freeze

# Current Bookshare API version.
#
# @type [String]
#
BOOKSHARE_API_VERSION =
  ENV.fetch('BOOKSHARE_API_VERSION', 'v2').freeze

# Base Bookshare API request path.
#
# @type [String]
#
BOOKSHARE_BASE_URL =
  ENV.fetch('BOOKSHARE_BASE_URL', 'https://api.bookshare.org')
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
