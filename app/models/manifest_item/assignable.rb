# app/models/manifest_item/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Assignable

  include ManifestItem::Config
  include ManifestItem::StatusMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Assignable
    # :nocov:
  end

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Ensure that blanks are allowed and that input values are normalized.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash]                                           opt
  #
  # @option opt [Boolean] :invalid      Allow invalid values.
  # @option opt [Symbol]  :meth         Caller (for diagnostics).
  # @option opt [Boolean] :re_validate  Caller will validate so skip that here.
  #
  # @return [Hash{Symbol=>*}]
  #
  def normalize_attributes(attr, **opt)
    opt[:errors] = ({} unless opt[:re_validate]) unless opt.key?(:errors)
    super(attr, compact: false, key_norm: true, **opt).tap do |result|
      unless opt[:re_validate]
        result[:field_error] = opt[:errors]
        update_status!(result, **opt.slice(*UPDATE_STATUS_OPTS))
      end
    end
  end

  # Include the default repository value if not specified.
  #
  # @param [Hash] attr
  #
  # @return [Hash]                    The *attr* argument, possibly modified.
  #
  def default_attributes!(attr)
    attr[:repository] ||= EmmaRepository.default unless ALLOW_NIL_REPOSITORY
    attr
  end

  # A mapping of key comparison value to actual database column name.
  #
  # @return [Hash{String=>Symbol}]
  #
  def key_mapping
    # noinspection RubyMismatchedReturnType
    @key_mapping ||= super
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
