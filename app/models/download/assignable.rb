# app/models/download/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Download::Assignable

  include Emma::Json

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Assignable
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Ensure that blanks are allowed and that input values are normalized.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash]                                           opt
  #
  # @return [Hash]
  #
  def normalize_attributes(attr, **opt)
    opt.reverse_merge!(key_norm: true, compact: false)
    super
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
