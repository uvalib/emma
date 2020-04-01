# app/models/concerns/file_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for objects created to access the content of an existing
# (already downloaded) file.
#
class FileParser < FileObject

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # metadata
  #
  # @return [OpenStruct]
  #
  def metadata
    raise "#{self.class}: #{__method__} not defined"
  end

  # Extracted metadata mapped to common metadata fields.
  #
  # @return [Hash]
  #
  def common_metadata
    raise "#{self.class}: #{__method__} not defined"
  end

end

__loading_end(__FILE__)
