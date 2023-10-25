# lib/ext/active_support/lib/active_support/core_ext/nil_class.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module NilClassExt

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ObjectExt
    # :nocov:
  end

  # ===========================================================================
  # :section: Instance methods to add to NilClass
  # ===========================================================================

  public

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

  # ===========================================================================
  # :section:
  # ===========================================================================

  # If there is ever a time when Rails or the standard Ruby library defines
  # one of these extension methods, any current uses of the method needs to be
  # evaluated and the local definition should be removed.
  if sanity_check?
    local  = instance_methods.excluding(:html_safe?)
    errors = local.intersection(NilClass.instance_methods)
    fail 'NilClass already defines %s' % errors.join(', ') if errors.present?
  end

end

class NilClass
  include NilClassExt
end

__loading_end(__FILE__)
