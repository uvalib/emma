# app/models/title.rb
#
# frozen_string_literal: true
# warn_indent:           true
#

__loading_begin(__FILE__)

# Model for a title (i.e., a catalog entry).
#
class Title < ApplicationRecord

  belongs_to :reading_list, optional: true

  has_many :artifacts

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  resourcify

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the title includes the indicated artifact.
  #
  # @param [String, Artifact]
  #
  def include?(item)
    has_artifact?(item)
  end

  # Indicate whether the title includes the indicated artifact.
  #
  # @param [String, Artifact]
  #
  def has_artifact?(item)
    if item.is_a?(String)
      artifacts.any? { |a| a.title_id == item }
    else
      artifacts.include?(item)
    end
  end

end

__loading_end(__FILE__)
