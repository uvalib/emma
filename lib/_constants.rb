# lib/_constants.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Constants set from configuration which are visible globally.
#
# For global properties which must be available during the boot sequence:
# @see config/env_vars.rb

require '_configuration'
require '_trace'

__loading_begin(__FILE__)

# =============================================================================
# Authorization
# =============================================================================

# Indicate whether Shibboleth authorization is in use.
#
# @type [Boolean]
#
SHIBBOLETH = !false?(ENV_VAR['SHIBBOLETH'])

# OmniAuth providers for Devise.
#
# @type [Array<Symbol>]
#
AUTH_PROVIDERS = [
  (:shibboleth if SHIBBOLETH),
].compact.freeze

if sanity_check?
  Log.warn('No AUTH_PROVIDERS (including SHIBBOLETH)') if AUTH_PROVIDERS.empty?
end

# A special conditional for supporting test sign in.
#
# @type [Symbol, nil]
#
SIGN_IN_AS = (:sign_in_as if Rails.env.test?)

# =============================================================================
# Mailer
# =============================================================================

MAILER_SENDER = ENV_VAR['MAILER_SENDER'].freeze

MAILER_URL_HOST =
  case
    when production_deployment? then URI.parse(PRODUCTION_URL).host.freeze
    when staging_deployment?    then URI.parse(STAGING_URL).host.freeze
    else                             'localhost'
  end

# =============================================================================
# EMMA Unified Ingest API
# =============================================================================

# EMMA Unified Ingest API key.
#
# This does not have a default and *must* be provided through the environment.
#
# @type [String, nil]
#
INGEST_API_KEY = ENV_VAR['INGEST_API_KEY'].freeze

# Current EMMA Unified Ingest API version.
#
# This is informational only; Ingest API URLs do not include it.
#
# @type [String]
#
# @see EmmaStatus#api_version
#
INGEST_API_VERSION = ENV_VAR['INGEST_API_VERSION'].freeze

# =============================================================================
# EMMA Unified Search API
# =============================================================================

# Current EMMA Unified Search API version.
#
# This is informational only; Search API URLs do not include it.
#
# @type [String]
#
SEARCH_API_VERSION = ENV_VAR['SEARCH_API_VERSION'].freeze

if sanity_check?
  # API versions are usually in sync.
  unless (vs = SEARCH_API_VERSION) == (vi = INGEST_API_VERSION)
    Log.warn { "Search API v#{vs} != Ingest API v#{vi}" }
  end
end

# =============================================================================
# Internet Archive
# =============================================================================

# IA S3 access key generated when logged in as Internet Archive user
# "emma_pull@archive.org".
#
# @type [String, nil]
#
# @see IaDownloadConcern#IA_AUTH
#
IA_ACCESS = ENV_VAR['IA_ACCESS'].freeze

# IA S3 secret generated when logged in as Internet Archive user
# "emma_pull@archive.org".
#
# @type [String, nil]
#
# @see IaDownloadConcern#IA_AUTH
#
IA_SECRET = ENV_VAR['IA_SECRET'].freeze

# IA server cookie for generation of "on-the-fly" content as Internet Archive
# user "emma_pull@archive.org".
#
# @type [String, nil]
#
# @see IaDownloadConcern#IA_COOKIES
#
IA_USER_COOKIE = ENV_VAR['IA_USER_COOKIE'].freeze

# IA server cookie for generation of "on-the-fly" content as Internet Archive
# user "emma_pull@archive.org".
#
# @type [String, nil]
#
# @see IaDownloadConcern#IA_COOKIES
#
IA_SIG_COOKIE = ENV_VAR['IA_SIG_COOKIE'].freeze

# Internet Archive "Printdisabled Unencrypted Ebook API" endpoint.
#
# @type [String]
#
IA_DOWNLOAD_API_URL =
  ENV_VAR['IA_DOWNLOAD_API_URL']
    .strip.sub(%r{^(http:)?//}, 'https://').sub(%r{/+$}, '').freeze

# =============================================================================
# Amazon Web Services
# =============================================================================

# Amazon AWS region.
#
# This should be supplied by the UVA cloud infrastructure on startup or from
# `Rails.application.credentials.s3`.
#
# @type [String]
#
AWS_REGION = ENV_VAR['AWS_REGION'].freeze

# Amazon S3 storage.
#
# Defined in the "terraform-infrastructure" GitLab project in the files
# "emma.lib.virginia.edu/ecs-tasks/staging/environment.vars" and
# "emma.lib.virginia.edu/ecs-tasks/production/environment.vars".
#
# @type [String]
#
AWS_BUCKET =
  ENV_VAR.fetch('AWS_BUCKET') { "emma-storage-#{aws_deployment}" }.freeze

# Amazon identity access key.
#
# This should be supplied by the UVA cloud infrastructure on startup or from
# `Rails.application.credentials.s3`.
#
# @type [String]
#
AWS_ACCESS_KEY_ID = ENV_VAR['AWS_ACCESS_KEY_ID'].freeze

# Amazon identity secret.
#
# This should be supplied by the UVA cloud infrastructure on startup or from
# `Rails.application.credentials.s3`.
#
# @type [String]
#
AWS_SECRET_KEY = ENV_VAR['AWS_SECRET_KEY'].freeze

# Amazon AWS region for BiblioVault collections.
#
# This should be supplied by the UVA cloud infrastructure on startup or from
# `Rails.application.credentials.bibliovault`.
#
# @type [String]
#
BV_REGION = ENV_VAR['BV_REGION'].freeze

# Amazon S3 storage for BiblioVault collections.
#
# @type [String]
#
BV_BUCKET =
  ENV_VAR.fetch('BV_BUCKET') {"bibliovault-transfer-#{aws_deployment}"}.freeze

# Amazon identity access key for BiblioVault collections.
#
# This should be supplied by the UVA cloud infrastructure on startup or from
# `Rails.application.credentials.bibliovault`.
#
# @type [String]
#
BV_ACCESS_KEY_ID = ENV_VAR['BV_ACCESS_KEY_ID'].freeze

# Amazon identity secret for BiblioVault collections.
#
# This should be supplied by the UVA cloud infrastructure on startup or from
# `Rails.application.credentials.bibliovault`.
#
# @type [String]
#
BV_SECRET_KEY = ENV_VAR['BV_SECRET_KEY'].freeze

# =============================================================================
# Logging
# =============================================================================

# Indicate whether the 'silencer' gem is enabled.
#
# Currently, attempting to replace system loggers (via Log#replace) ends up
# defeating the ability of the 'silencer' gem to eliminate *all* log entries
# for the endpoints on which it operates.
#
# @type [bool]
#
LOG_SILENCER = !false?(ENV_VAR['LOG_SILENCER'])

# Application endpoints which are intended to leave no footprint in the log.
#
# @type [Array<String,Regexp>]
#
LOG_SILENCER_ENDPOINTS =
  ENV_VAR['LOG_SILENCER_ENDPOINTS'].then { |endpoints|
    if endpoints.is_a?(String)
      endpoints.strip.sub(/^\[(.*)\]$/, '\1').split(/[;,|\t\n]/).map do |v|
        v = v.strip.sub(/^"(.*)"$/, '\1').gsub(/\\\\/, '\\')
        regexp(v) || (v.start_with?('/') ? v : "/#{v}") if v.present?
      end
    else
      endpoints
    end
  }.compact.map(&:freeze).freeze

# =============================================================================
# Debugging
# =============================================================================

# Control creation of 'data-trace-*' attributes on HTML elements.
#
# @see BaseDecorator::Common#trace_attrs
#
DEBUG_ATTRS = true?(ENV_VAR['DEBUG_ATTRS'])

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [Boolean]
#
DEBUG_AWS = true?(ENV_VAR['DEBUG_AWS'])

# Set to debug ActionCable interactions.
#
# @type [Boolean]
#
DEBUG_CABLE = true?(ENV_VAR['DEBUG_CABLE'])

# Set to debug YAML configuration.
#
# @type [Boolean]
#
DEBUG_CONFIGURATION = true?(ENV_VAR['DEBUG_CONFIGURATION'])

# Set to set the :debug option for Rack::Cors.
#
# @type [Boolean]
#
DEBUG_CORS = true?(ENV_VAR['DEBUG_CORS'])

# Set to show low-level bulk import processing.
#
# @type [Boolean]
#
DEBUG_IMPORT = true?(ENV_VAR['DEBUG_IMPORT'])

# When *true* invocation of each low-level IO operation triggers a log debug
# entry.
#
# @type [Boolean]
#
DEBUG_IO = true?(ENV_VAR['DEBUG_IO'])

# When *true* ActiveJob debugging callbacks are invoked.
#
# @type [Boolean]
#
DEBUG_JOB = true?(ENV_VAR['DEBUG_JOB'])

# Set to show registration of unique MIME types during startup.
#
# @type [Boolean]
#
DEBUG_MIME_TYPE = true?(ENV_VAR['DEBUG_MIME_TYPE'])

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [Boolean]
#
DEBUG_OAUTH = true?(ENV_VAR['DEBUG_OAUTH']) || true?(ENV_VAR['OAUTH_DEBUG'])

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @note This is different than 'PUMA_DEBUG', which causes Puma to turn on its
#   own internal debugging statements.
#
# @type [Boolean]
#
DEBUG_PUMA = true?(ENV_VAR['DEBUG_PUMA'])

# Set internal debugging of Representable pipeline actions.
#
# - *false* for normal operation
# - *true*  for full debugging
# - :input  for debugging parsing/de-serialization.
# - :output for debugging rendering/serialization.
#
# @type [Boolean, Symbol]
#
DEBUG_REPRESENTABLE =
  ENV_VAR['DEBUG_REPRESENTABLE'].then do |v|
    v = v.strip.downcase if v.is_a?(String)
    case v
      when nil                  then false
      when true, false, Symbol  then v
      when *TRUE_VALUES         then true
      when *FALSE_VALUES        then false
      when String               then v.delete_prefix(':').to_sym
    end
  end

# When *true* invocation of each low-level IO operation triggers a log entry.
#
# @type [Boolean]
#
DEBUG_SHRINE = true?(ENV_VAR['DEBUG_SHRINE'])

# When *true* debug asset pipeline timings in "rake 'assets:precompile'".
#
# @type [Boolean]
#
DEBUG_SPROCKETS = true?(ENV_VAR['DEBUG_SPROCKETS'])

# Set to show better information from Concurrent Ruby.
#
# @type [Boolean]
#
DEBUG_THREADS = true?(ENV_VAR['DEBUG_THREADS'])

# Set to show headers and data being sent to external APIs.
#
# @type [Boolean]
#
DEBUG_TRANSMISSION = true?(ENV_VAR['DEBUG_TRANSMISSION'])

# Indicate whether debugging of view files is active.
#
# @type [Boolean]
#
DEBUG_VIEW = true?(ENV_VAR['DEBUG_VIEW'])

# Debug workflow steps.
#
# @type [Boolean]
#
DEBUG_WORKFLOW = true?(ENV_VAR['DEBUG_WORKFLOW'])

# Debug workflow steps.
#
# @type [Boolean]
#
DEBUG_RECORD = true?(ENV_VAR['DEBUG_RECORD'])

# Set to show low-level XML parse logging.
#
# @type [Boolean]
#
DEBUG_XML_PARSE = true?(ENV_VAR['DEBUG_XML_PARSE'])

# When *true* debug loading at startup.
#
# @type [Boolean]
#
DEBUG_ZEITWERK = true?(ENV_VAR['DEBUG_ZEITWERK'])

__loading_end(__FILE__)
