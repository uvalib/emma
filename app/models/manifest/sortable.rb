# app/models/manifest/sortable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Manifest::Sortable

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Sortable
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Sortable overrides
  # ===========================================================================

  public

  # Sort order applied by default in #get_relation.
  #
  # @return [Symbol, String, Hash]
  #
  def default_sort
    { implicit_order_column => :desc }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
