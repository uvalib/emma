# config/env_vars.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Set key environment variables and global properties.

require_relative 'boot'
require 'tmpdir'

# =============================================================================
# Operational properties
# =============================================================================

# Temporary directory.
#
# If provided as a relative path it will be expanded to the full absolute path.
#
# @type [String]
#
TMPDIR =
  if defined?(Rails)
    Dir.tmpdir.sub(%r{^([^/])}, Rails.root.join('\1').to_path)
  else
    File.expand_path(Dir.tmpdir, File.absolute_path('..'))
  end.freeze

# OAuth2 providers for Devise.
#
# @type [Array<Symbol>]
#
OAUTH2_PROVIDERS = %i[bookshare].freeze

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
# EMMA Federated Ingest API properties
# =============================================================================

# EMMA Federated Ingest API key.
#
# This does not have a default and *must* be provided through the environment.
#
# @type [String, nil]
#
INGEST_API_KEY = ENV.fetch('INGEST_API_KEY', nil).freeze

# Current EMMA Federated Ingest API version.
#
# This is informational only; search API URLs do not include it.
#
# @type [String]
#
INGEST_API_VERSION = ENV.fetch('INGEST_API_VERSION', '0.0.3').freeze

# Base EMMA Federated Ingest API request path.
#
# @type [String]
#
INGEST_BASE_URL =
  ENV.fetch('INGEST_BASE_URL', 'https://ingest.staging.bookshareunifiedsearch.org')
    .strip
    .sub(%r{^(http:)?//}, 'https://')
    .sub(%r{/+$}, '')
    .freeze

# =============================================================================
# Internet Archive access
# =============================================================================

# IA S3 access key generated when logged in as Internet Archive user
# "emma_pull@archive.org".
#
# @type [String]
#
# @see IaDownloadConcern#IA_AUTH
#
IA_ACCESS = ENV.fetch('IA_ACCESS', nil).freeze

# IA S3 secret generated when logged in as Internet Archive user
# "emma_pull@archive.org".
#
# @type [String]
#
# @see IaDownloadConcern#IA_AUTH
#
IA_SECRET = ENV.fetch('IA_SECRET', nil).freeze

# IA server cookie for generation of "on-the-fly" content as Internet Archive
# user "emma_pull@archive.org".
#
# @type [String]
#
# @see IaDownloadConcern#IA_COOKIES
#
IA_USER_COOKIE = ENV.fetch('IA_USER_COOKIE', nil).freeze

# IA server cookie for generation of "on-the-fly" content as Internet Archive
# user "emma_pull@archive.org".
#
# @type [String]
#
# @see IaDownloadConcern#IA_COOKIES
#
IA_SIG_COOKIE = ENV.fetch('IA_SIG_COOKIE', nil).freeze

# Base Internet Archive download path.
#
# @type [String]
#
IA_DOWNLOAD_BASE_URL =
  ENV.fetch('IA_DOWNLOAD_BASE_URL', 'https://archive.org/download')
    .strip
    .sub(%r{^(http:)?//}, 'https://')
    .sub(%r{/+$}, '')
    .freeze

# =============================================================================
# Amazon Web Services
# =============================================================================

# Amazon AWS region.
#
# This should be supplied by the UVA cloud infrastructure on startup.
#
# @type [String]
#
AWS_REGION = ENV.fetch('AWS_REGION', 'us-east-1').freeze

# Amazon S3 storage.
#
# Defined in the "terraform-infrastructure" GitLab project in the files
# "emma.lib.virginia.edu/ecs-tasks/staging/environment.vars" and
# "emma.lib.virginia.edu/ecs-tasks/production/environment.vars".
#
# @type [String]
#
AWS_BUCKET =
  ENV.fetch('AWS_BUCKET') { "emma-storage-#{application_deployment}" }.freeze

# Amazon identity access key.
#
# This should be supplied by the UVA cloud infrastructure on startup.
#
# @type [String]
#
AWS_ACCESS_KEY_ID = ENV.fetch('AWS_ACCESS_KEY_ID', nil).freeze

# Amazon identity secret.
#
# This should be supplied by the UVA cloud infrastructure on startup.
#
# @type [String]
#
AWS_SECRET_KEY = ENV.fetch('AWS_SECRET_KEY', nil).freeze

# =============================================================================
# Output
# =============================================================================

# Control console debugging output.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
CONSOLE_DEBUGGING = true?(ENV['CONSOLE_DEBUGGING'])

# Control console output.
#
# Normally __output (and __debug) are not displayed in non-Rails invocations of
# the code (e.g. rake, irb, etc) unless CONSOLE_DEBUGGING is *true*.
#
CONSOLE_OUTPUT = rails_application? || CONSOLE_DEBUGGING

# Control tracking of file load order.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__loading
#
TRACE_LOADING = true?(ENV['TRACE_LOADING'])

# Control tracking of invocation of Concern "included" blocks.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #__included
#
TRACE_CONCERNS = true?(ENV['TRACE_CONCERNS'])

# Control tracking of Rails notifications.
#
# During normal operation this should be set to *false*.  Change the default
# value here or override dynamically with the environment variable.
#
# @see #NOTIFICATIONS
#
TRACE_NOTIFICATIONS = true?(ENV['TRACE_NOTIFICATIONS'])

# =============================================================================
# Debugging
# =============================================================================

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [Boolean]
#
DEBUG_AWS = true?(ENV['DEBUG_AWS'])

# Set to show low-level bulk import processing.
#
# @type [Boolean]
#
DEBUG_IMPORT = true?(ENV['DEBUG_IMPORT'])

# When *true* invocation of each low-level IO operation triggers a log debug
# entry.
#
# @type [Boolean]
#
DEBUG_IO = true?(ENV['DEBUG_IO'])

# Set to show registration of unique MIME types during startup.
#
# @type [Boolean]
#
DEBUG_MIME_TYPE = true?(ENV['DEBUG_MIME_TYPE'])

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [Boolean]
#
DEBUG_OAUTH =
  true?(ENV['OAUTH_DEBUG']) ||
  true?(ENV['DEBUG_OAUTH']).tap { |on| ENV['DEBUG_OAUTH'] = 'true' if on }

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [Boolean]
#
DEBUG_PUMA = true?(ENV['DEBUG_PUMA'])

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [Boolean]
#
DEBUG_SHRINE = true?(ENV['DEBUG_SHRINE'])

# Debug workflow steps.
#
# @type [Boolean]
#
DEBUG_WORKFLOW = true?(ENV['DEBUG_WORKFLOW'])

# Set to show low-level XML parse logging.
#
# @type [Boolean]
#
DEBUG_XML_PARSE = true?(ENV['DEBUG_XML_PARSE'])
