# app/models/manifest/emma_identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Manifest::EmmaIdentification

  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::EmmaIdentification
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # @private
  UUID_PATTERN = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  # Indicate whether the value could be a valid #id_column value.
  #
  # @param [any, nil] value
  #
  def valid_id?(value)
    value.is_a?(String) && value.match?(UUID_PATTERN)
  end

  # UUID identifiers can't be grouped into ranges.
  #
  # @param [Array<String>] ids
  #
  # @return [Array<String>]
  #
  def group_ids(*ids, **)
    ids.sort.uniq
  end

  # There is no "minimum" UUID.
  #
  # @return [nil]
  #
  def minimum_id(...)
  end

  # There is no "maximum" UUID.
  #
  # @return [nil]
  #
  def maximum_id(...)
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
