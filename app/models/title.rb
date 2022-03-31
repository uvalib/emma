# app/models/title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for a title (i.e., a catalog entry).
#
class Title < ApplicationRecord

  include Model

  include Record
  include Record::Authorizable

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  has_and_belongs_to_many :artifacts
  has_and_belongs_to_many :reading_lists

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the title includes the indicated artifact.
  #
  # @param [Artifact, String, *] item
  #
  def include?(item)
    has_artifact?(item)
  end

  # Indicate whether the title includes the indicated artifact.
  #
  # @param [Artifact, String, *] item
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
