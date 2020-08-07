# lib/emma/constants.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Emma::Constants
#
module Emma::Constants

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The web site for project information.
  #
  # @type [String]
  #
  PROJECT_SITE = 'https://emma.uvacreate.virginia.edu'

  # The email address for project information.
  #
  # @type [String]
  #
  PROJECT_EMAIL = 'emma4accessibility@virginia.edu'

  # The email address for support and general information.
  #
  # @type [String]
  #
  CONTACT_EMAIL = 'emmahelp@virginia.edu'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # String to cause text to continue on the next line within an HTML element.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  HTML_NEW_LINE = "<br/>\n".html_safe.freeze

end

__loading_end(__FILE__)
