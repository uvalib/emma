# lib/emma/constants.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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
  'emmacollection@bookshare.org' => '13350912-e2f8-4111-ac7e-c04b608ff3c1',
  'emmadso@bookshare.org'        => '00eb7f83-6917-479b-ae78-c819bec8770f'
}.freeze

# Bookshare API key.
#
# This does not have a default and *must* be provided through the environment.
#
# @type [String]
#
BOOKSHARE_API_KEY = ENV.fetch('BOOKSHARE_API_KEY').freeze

# Current Bookshare API version.
#
# @type [String]
#
BOOKSHARE_API_VERSION = ENV.fetch('BOOKSHARE_API_VERSION', 'v2').freeze

# Base Bookshare authentication service path.
#
# @type [String]
#
BOOKSHARE_AUTH_URL =
  ENV.fetch('BOOKSHARE_AUTH_URL', 'https://auth.bookshare.org').freeze

# Base Bookshare API request path.
#
# @type [String]
#
BOOKSHARE_BASE_URL =
  ENV.fetch('BOOKSHARE_BASE_URL', 'https://api.bookshare.org')
    .sub(%r{^(https?://)?}) { $1 || 'https://' }
    .sub(%r{(/v\d+/?)?$})   { $1 || "/#{BOOKSHARE_API_VERSION}" }
    .freeze

# Emma::Constants
#
module Emma::Constants

  # Subnet for production systems.
  PRODUCTION_SUBNET = 'lib.virginia.edu'

  # String to cause text to continue on the next line within an HTML element.
  HTML_NEW_LINE = "<br/>\n".html_safe.freeze

  # Organizational information.
  #
  module VCard
    ORGANIZATION  = 'University of Virginia Library'
    ADDRESS       = 'PO Box 400113, Charlottesville, VA 22904-4113'
    TELEPHONE     = '434-924-3021'
    FAX           = '434-924-1431'
    EMAIL         = 'library@virginia.edu'
  end

  # External URLs.
  #
  module URL

    UVA_HOST        = 'www.virginia.edu'
    UVA_ROOT        = "http://#{UVA_HOST}"
    UVA_HOME        = UVA_ROOT
    COPYRIGHT       = "#{UVA_ROOT}/siteinfo/copyright"

    ITS_HOST        = 'its.virginia.edu'
    ITS_ROOT        = "http://#{ITS_HOST}"
    ITS_HOME        = ITS_ROOT
    NETBADGE_INFO   = "#{ITS_ROOT}/netbadge/"

    NETBADGE_HOST   = 'netbadge.virginia.edu'
    NETBADGE_ROOT   = "https://#{NETBADGE_HOST}"
    NETBADGE_LOGIN  = NETBADGE_ROOT
    NETBADGE_LOGOUT = "#{NETBADGE_ROOT}/logout.cgi"

  end

end

__loading_end(__FILE__)
