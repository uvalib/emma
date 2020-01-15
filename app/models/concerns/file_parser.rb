# app/models/concerns/file_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for objects created to access the content of an existing
# (already downloaded) file.
#
class FileParser < LocalFile

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # metadata
  #
  # @return [*]                       Type is specific to the subclass.
  #
  def metadata
    raise "#{self.class}: #{__method__} not defined"
  end

end

__loading_end(__FILE__)
