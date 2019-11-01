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
  'emmadso@bookshare.org'        => 'c1060fe1-1625-4401-8f63-d7fe8a802ee8',
  'emmacollection@bookshare.org' => '36e826af-fe72-483e-be11-b46a7425f14c',
  'emmamembership@bookshare.org' => '36e826af-fe72-483e-be11-b46a7425f14c',
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
