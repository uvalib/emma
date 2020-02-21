# app/models/artifact.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for database record models.
#
class ApplicationRecord < ActiveRecord::Base

  self.abstract_class = true

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Two records match if their contents are the same.
  #
  # @param [ApplicationRecord, *] other
  #
  def match?(other)
    self.class.match?(self, other)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Indicate whether two records match.
  #
  # @param [ApplicationRecord] rec_1
  # @param [ApplicationRecord] rec_2
  #
  def self.match?(rec_1, rec_2)
    (rec_1.is_a?(ApplicationRecord) || rec_2.is_a?(ApplicationRecord)) &&
      (rec_1.class == rec_2.class) &&
      (rec_1.attributes == rec_2.attributes)
  end

end

__loading_end(__FILE__)
