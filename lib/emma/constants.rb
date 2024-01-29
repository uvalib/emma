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

  # Field value used to explicitly indicate missing data.
  #
  # @type [String]
  #
  EMPTY_VALUE = Emma::Unicode::EN_DASH

end

__loading_end(__FILE__)
