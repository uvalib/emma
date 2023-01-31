# app/models/manifest_item/identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Identification

  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Identification
    # :nocov:
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Column name for the identifier of the associated user.
  #
  # @return [nil]
  #
  def user_column
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
