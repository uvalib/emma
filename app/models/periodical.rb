# app/models/periodical.rb
#
# frozen_string_literal: true
# warn_indent:           true
#

__loading_begin(__FILE__)

# Model for a periodical.
#
class Periodical < ApplicationRecord

  belongs_to :reading_list, optional: true

=begin # TODO: artifacts?
  has_many :artifacts
=end
  has_many :editions

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the periodical includes the indicated artifact.
  #
  # @param [String, Artifact]
  #
  def include?(item)
    has_artifact?(item)
  end

  # Indicate whether the periodical includes the indicated artifact.
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