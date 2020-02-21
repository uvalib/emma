# app/models/concerns/cached_file.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# CachedFile
#
class CachedFile < FileObject

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Stream for accessing file contents.
  #
  # @type [IO, StringIO, nil]
  #
  attr_reader :io

  # ===========================================================================
  # :section: FileObject overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [String, StringIO, IO] io
  # @param [Hash]                 opt
  #
  # This method overrides:
  # @see FileObject#initialize
  #
  def initialize(io = nil, **opt)
    @io = io
    if @io.present? # TODO: remove
      class_name = self.class.to_s
      class_name += ' (CachedFile)' unless class_name == 'CachedFile'
      __debug_args(binding, leader: "... NEW #{class_name}")
    end
    super(io, **opt)
  end

end

__loading_end(__FILE__)
