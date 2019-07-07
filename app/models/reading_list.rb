# app/models/reading_list.rb
#
# frozen_string_literal: true
# warn_indent:           true
#

__loading_begin(__FILE__)

# Model for a Reading List.
#
class ReadingList < ApplicationRecord

  has_many :titles
  has_many :editions
  has_many :artifacts, through: :titles
  has_many :artifacts, through: :editions

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  resourcify

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the reading list includes the indicated title or artifact.
  #
  # @param [String, Title, Artifact]
  #
  def include?(item)
    has_title?(item) || has_artifact?(item)
  end

  # Indicate whether the reading list includes the indicated title.
  #
  # @param [String, Title]
  #
  def has_title?(item)
    if item.is_a?(String)
      titles.any? { |t| t.bookshareId == item }
    else
      titles.include?(item)
    end
  end

  # Indicate whether the reading list includes the indicated artifact.
  #
  # @param [String, Artifact]
  #
  def has_artifact?(item)
    if item.is_a?(String)
      artifacts.any? { |a| a.id == item }
    else
      artifacts.include?(item)
    end
  end

end

__loading_end(__FILE__)
