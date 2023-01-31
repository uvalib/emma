# app/models/manifest/emma_identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Manifest::EmmaIdentification

  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::EmmaIdentification
    # :nocov:
  end

  # ===========================================================================
  # :section: Record::EmmaIdentification overrides
  # ===========================================================================

  public

  # Column name for the submission ID.
  #
  # @return [nil]
  #
  def sid_column
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # @private
  UUID_PATTERN = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  # Indicate whether the value could be a valid #id_column value.
  #
  # @param [*] value
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
    ids.sort!.uniq!
    ids
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
