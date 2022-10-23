# app/models/manifest_item/emma_identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::EmmaIdentification

  include Record::EmmaIdentification

  # ===========================================================================
  # :section: Record::EmmaIdentification overrides
  # ===========================================================================

  public

  # Column name for the submission ID.
  #
  # @return [nil]
  #
  def sid_column
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
