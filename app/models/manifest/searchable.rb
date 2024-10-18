# app/models/manifest/searchable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Manifest::Searchable

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Searchable
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Searchable overrides
  # ===========================================================================

  public

  # Because UUIDs are not ordered, Manifests can't support pagination as it is
  # currently implemented.
  #
  # @return [nil]
  #
  def pagination_column
    Log.debug { "#{__method__}: not defined for #{self_class}" }
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
