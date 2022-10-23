# app/models/manifest_item/validatable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Validatable

  include Record::Validatable

  # ===========================================================================
  # :section: Record::Validatable overrides
  # ===========================================================================

  public

  # Configured requirements for ManifestItem fields.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def database_fields
    Model.database_fields(:manifest_item)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
