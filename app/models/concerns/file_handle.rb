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

  include Emma::Debug

  # An object with one of these types may be used as the underlying handle.
  #
  # @type [Array<Module>]
  #
  VALID_BASE_TYPE = [IO, StringIO, Tempfile, IO::Like, Down::ChunkedIO].freeze

  # Indicate whether the given object may be used to create a FileHandle.
  #
  # @param [IO, StringIO, Tempfile, *] value
  #
  def self.compatible?(value)
    value.is_a?(FileHandle) || VALID_BASE_TYPE.any? { |t| value.is_a?(t) }
  end

  # Initialize a new instance.
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
    __debug_items(file, separator: ' | ', leader: "FileHandle | initialize | #{file.class}")
    @handle =
      case file
        when String     then File.new(file)
        when FileHandle then file.handle
        else                 file
      end
    raise "#{file.class} incompatible" unless self.class.compatible?(@handle)
  end

  # method_missing
  #
  # @param [Symbol] name
  # @param [Array]  args
  #
  # @return [*]
  #
  def method_missing(name, *args, &block)
    __debug_items(*args, separator: ' | ', leader: ("FileHandle | #{@handle.class} %-4s" % name))
    @handle.send(name, *args, &block) #if @handle.respond_to?(name)
  rescue => e
    Log.error "!!! EXCEPTION IN FileHandle: #{e.class} #{e.message}\n#{caller.pretty_inspect}"
  end

  protected

  # @type [IO, StringIO, Tempfile, IO::Like, Down::ChunkedIO]
  attr_reader :handle

end

__loading_end(__FILE__)
