# lib/emma/constants.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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
