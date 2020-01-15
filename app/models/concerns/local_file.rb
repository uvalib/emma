# app/models/concerns/local_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A downloaded file object which is present in a local file system.
#
class LocalFile < FileObject

  # ===========================================================================
  # :section: FileObject overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [String] file
  # @param [Hash]   opt
  #
  # This method overrides:
  # @see FileObject#initialize
  #
  def initialize(file, **opt)
    if path.present? # TODO: remove
      class_name = self.class.to_s
      class_name += ' (LocalFile)' unless class_name == 'LocalFile'
      __debug_args(binding, leader: "... NEW #{class_name}")
    end
    super(file, **opt)
    @filename = file
  end

  # ===========================================================================
  # :section: FileAttributes overrides
  # ===========================================================================

  public

  # local_path
  #
  # @return [String]
  #
  # This method overrides:
  # @see FileAttributes#local_path
  #
  def local_path
    @local_path ||= path
  end

end

__loading_end(__FILE__)
