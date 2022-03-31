# app/models/reading_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a Reading List.
#
class ReadingList < ApplicationRecord

  include Model

  include Record
  include Record::Authorizable

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  belongs_to :user, optional: true

  has_and_belongs_to_many :members
  has_and_belongs_to_many :editions
  has_and_belongs_to_many :titles

  # noinspection RailsParamDefResolve
  has_many :artifacts, through: :editions

  # noinspection RailsParamDefResolve
  has_many :artifacts, through: :titles

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the reading list includes the indicated title or artifact.
  #
  # @param [Title, Artifact, String, *] item
  #
  def include?(item)
    # noinspection RubyMismatchedArgumentType
    has_title?(item) || has_artifact?(item)
  end

  # Indicate whether the reading list includes the indicated title.
  #
  # @param [Title, String, *] item
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
  # @param [Artifact, String, *] item
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
