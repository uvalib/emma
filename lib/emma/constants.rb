# lib/emma/constants.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'emma/unicode'

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

  # Field value used to explicitly indicate missing data.
  #
  # @type [String]
  #
  EMPTY_VALUE = Emma::Unicode::EN_DASH

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
