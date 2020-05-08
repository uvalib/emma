# app/records/bs/shared/periodical_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to periodicals.
#
# Attributes supplied by the including module:
#
# @attr [String] title
# @attr [String] seriesId
#
module Bs::Shared::PeriodicalMethods

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Convert object to string.
  #
  # @return [String]
  #
  def to_s
    label
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    title.to_s
  end

  # Return the unique identifier for the represented periodical.
  #
  # @return [String]
  #
  def identifier
    seriesId.to_s
  end

end

__loading_end(__FILE__)
