# app/models/org/_config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Org::Config

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The internal organization identifier.  This may be assigned as an :org_id
  # indicating an internal EMMA user, however no persisted Org record has this
  # as its :id.
  #
  # @type [Integer]
  #
  INTERNAL_ID = 0

  # The display name for the internal organization.
  #
  # @type [String]
  #
  INTERNAL_NAME = '(EMMA)'

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
  # @return [*, Org]
  #
  def default_to_self(item = nil, from: nil)
    return item if item
    return self if self.is_a?(Org)
    meth = from || calling_method
    raise "#{meth} not being used as a record instance method"
  end

end

__loading_end(__FILE__)
