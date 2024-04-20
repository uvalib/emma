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

  # Field value used to explicitly indicate missing data when rendering.
  #
  # @type [String]
  #
  EMPTY_VALUE = Emma::Unicode::EN_DASH

  # A field value indicating that the field should be cleared/removed from the
  # associated record.
  #
  # (Blank field values assumed to be form fields that were not filled in and
  # are thus ignored when updating the associated record).
  #
  # @type [String]
  #
  DELETED_FIELD = "\x7f\x7f"

end

__loading_end(__FILE__)
