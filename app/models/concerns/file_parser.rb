# app/models/concerns/file_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for objects created to access the content of an existing
# (already downloaded) file.
#
class FileParser < FileObject

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    to_be_overridden
  end

  # Extracted metadata mapped to common metadata fields.
  #
  # @return [Hash]
  #
  def common_metadata
    to_be_overridden
  end

end

# =============================================================================
# Pre-load format-specific classes for easier TRACE_LOADING.
# =============================================================================

require_subclasses(__FILE__)

__loading_end(__FILE__)
