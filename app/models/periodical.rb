# app/models/periodical.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a periodical.
#
class Periodical < ApplicationRecord

  has_and_belongs_to_many :editions

  # noinspection RailsParamDefResolve
  has_many :artifacts, through: :editions

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  resourcify

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the periodical includes the indicated artifact.
  #
  # @param [String, Artifact] item
  #
  def include?(item)
    has_artifact?(item)
  end

  # Indicate whether the periodical includes the indicated artifact.
  #
  # @param [String, Artifact] item
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
