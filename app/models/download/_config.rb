# app/models/download/_config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Download::Config

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Used by methods defined in modules to allow the primary argument to be
  # missing/nil when used as a record instance method.
  #
  # @param [*, nil] item
  # @param [Symbol] from
  #
  # @return [*, Download]
  #
  def default_to_self(item = nil, from: nil)
    return item if item
    return self if self.is_a?(Download)
    meth = from || calling_method
    raise "#{meth} not being used as a record instance method"
  end

end

__loading_end(__FILE__)
