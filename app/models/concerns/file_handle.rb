# app/models/concerns/file_handle.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'io/like'
require 'down/chunked_io'

# An IO-like file object based on a number of types which are conceptually
# related but do not actually share a common ancestor.
#
class FileHandle

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # An object with one of these types may be used as the underlying handle.
  #
  # @type [Array<Module>]
  #
  VALID_BASE_TYPE = [IO, StringIO, Tempfile, IO::Like, Down::ChunkedIO].freeze

  # Indicate whether the given object may be used to create a FileHandle.
  #
  # @param [IO, StringIO, Tempfile, IO::Like, Down::ChunkedIO, *] value
  #
  def self.compatible?(value)
    value.is_a?(FileHandle) || VALID_BASE_TYPE.any? { |t| value.is_a?(t) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Expose @handle for use in #initialize.
  #
  # @type [IO, StringIO, Tempfile, IO::Like, Down::ChunkedIO]
  #
  attr_reader :handle

  # Initialize a new instance.
  #
  # @param [FileHandle, String, IO, StringIO, Tempfile, Down::ChunkedIO] file
  #
  # @raise [StandardError]            If *file* is invalid.
  #
  # == Variations
  #
  # @overload initialize(other)
  #   @param [FileHandle] other
  #
  # @overload initialize(path)
  #   @param [String] path
  #
  # @overload initialize(file)
  #   @param [IO, StringIO, Tempfile, IO::Like, Down::ChunkedIO] file
  #
  def initialize(file)
    __debug_handle(file, leader: "initialize | #{file.class}")
    @handle =
      case file
        when String     then File.new(file)
        when FileHandle then file.handle
        else                 file
      end
    raise "#{file.class} incompatible" unless self.class.compatible?(@handle)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  if not DEBUG_IO

    def __debug_handle(*); end

    delegate_missing_to :@handle

  else

    include Emma::Debug::OutputMethods

    # Debug method for this class.
    #
    # @param [Array] args
    # @param [Hash]  opt
    # @param [Proc]  block              Passed to #__debug_items.
    #
    # @return [void]
    #
    def __debug_handle(*args, **opt, &block)
      sep = opt[:separator] ||= ' | '
      opt[:leader] = [*opt[:leader], 'FileHandle'].compact.join(sep)
      __debug_items(*args, opt, &block)
    end

    # Indicate whether the underlying object implements the given method.
    #
    # @param [Symbol, String] name
    # @param [Boolean]        include_private
    #
    def respond_to_missing?(name, include_private = false)
      @handle.respond_to?(name, include_private) || super
    end

    # Delegate to the underlying object.
    #
    # @param [Symbol, String] name
    # @param [Array]          args
    # @param [Proc]           block
    #
    # @return [*]
    #
    def method_missing(name, *args, &block)
      __debug_handle(*args, leader: ("#{@handle.class} %-4s" % name))
      @handle.send(name, *args, &block)
    rescue => e
      Log.error do
        "FileHandle: in method_missing: #{e.class} #{e.message} - stack:\n" +
          caller.pretty_inspect
      end
    end

  end

end

__loading_end(__FILE__)
