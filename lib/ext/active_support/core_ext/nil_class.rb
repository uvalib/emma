# lib/ext/active_support/core_ext/nil_class.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class NilClass

  # This prevents values that might be *nil* from causing a problem in ERB
  # templates when used in a context where an empty string would be acceptable.
  #
  # @return [nil]
  #
  def html_safe
    nil
  end

  # Indicates that *nil* is treated as HTML-safe.
  #
  def html_safe?
    true
  end

end

__loading_end(__FILE__)
