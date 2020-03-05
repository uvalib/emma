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

=begin
  # Stream for accessing file contents.
  #
  # @type [IO, StringIO, nil]
  #
  attr_reader :io
=end

  # ===========================================================================
  # :section: FileObject overrides
  # ===========================================================================

  public

=begin
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
    super(io, **opt)
  end
=end

end

__loading_end(__FILE__)
