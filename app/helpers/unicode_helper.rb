# app/helpers/unicode_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Unicode utilities.
#
module UnicodeHelper

  def self.included(base)
    __included(base, '[UnicodeHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  BLACK_CIRCLE  = "\u25CF"
  EM_SPACE      = "\u2003"
  EN_SPACE      = "\u2002"

end

__loading_end(__FILE__)
