# lib/ext/active_support/lib/active_support/core_ext/nil_class.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module NilClassExt

  include SystemExtension

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
  # :section: SystemExtension overrides
  # ===========================================================================

  public

  # This method checks that the methods defined in *ext* are not already
  # defined in *mod*.
  #
  # @param [Module] mod             The module or class that is being extended.
  # @param [Module] ext             The module with new or override methods.
  # @param [Hash]   opt             Passed to super.
  #
  def self.check_extension(mod, ext, **opt)
    opt[:except] ||= %i[html_safe?]
    super(mod, ext, **opt)
  end

end

class NilClass

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include NilClassExt
    # :nocov:
  end

  NilClassExt.include_in(self)

end

__loading_end(__FILE__)
