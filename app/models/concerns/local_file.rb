# app/models/concerns/local_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A downloaded file object which is present in a local file system.
#
class LocalFile < FileObject

=begin
  # ===========================================================================
  # :section: FileObject overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [IO, StringIO, String] file
  # @param [Hash]                 opt
  #
  # This method overrides:
  # @see FileObject#initialize
  #
  def initialize(file, **opt)
    super(file, **opt)
  end
=end

  # ===========================================================================
  # :section: FileAttributes overrides
  # ===========================================================================

  public

=begin
  # local_path
  #
  # @return [String, StringIO, IO, nil]
  #
  # This method overrides:
  # @see FileAttributes#local_path
  #
  def local_path
    @local_path ||= path
  end
=end

=begin
  # file_handle
  #
  # @return [File, StringIO, nil]
  #
  def file_handle
    @file_handle ||= (File.open(filename) if filename.present?)
  end
=end

end

__loading_end(__FILE__)
