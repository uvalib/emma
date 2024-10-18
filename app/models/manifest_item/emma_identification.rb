# app/models/manifest_item/emma_identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::EmmaIdentification

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::EmmaIdentification
  end
  # :nocov:

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
    base.extend(self)
  end

end

__loading_end(__FILE__)
