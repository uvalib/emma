# config/environment.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Set key environment variables and operational settings then start the Rails
# application.

# =============================================================================
# Operational properties
# =============================================================================

public

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
# Bookshare API properties
# =============================================================================

public

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

public

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

public

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

public

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

public

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
# Verify required environment variables
# =============================================================================

if rails_application?
  vars = [
    # === Bookshare authentication
    :BOOKSHARE_AUTH_URL,

    # === Bookshare API
    :BOOKSHARE_API_KEY,
    :BOOKSHARE_API_VERSION,
    :BOOKSHARE_BASE_URL,

    # === EMMA Unified Index API
    :SEARCH_BASE_URL,

    # === EMMA Federated Ingest API
    :INGEST_BASE_URL,
    :INGEST_API_KEY,

    # === Internet Archive downloads
    :IA_DOWNLOAD_BASE_URL,
    :IA_ACCESS,
    :IA_SECRET,
    :IA_SIG_COOKIE,
    :IA_USER_COOKIE,
  ]
  if application_deployed? || !development_build?
    # == Amazon Web Services
    vars += %i[AWS_REGION AWS_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_KEY]
  end
  vars.each do |var|
    if self.class.const_defined?(var)
      v = self.class.const_get(var)
      STDERR.puts "Empty #{var}" if v.respond_to?(:empty?) ? v.empty? : v.nil?
    else
      STDERR.puts "Missing #{var}"
    end
  end
end

# =============================================================================
# Load and initialize the Rails application
# =============================================================================

require_relative 'application'

Rails.application.initialize!
