# lib/ext/down/lib/down/chunked_io.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Down gem.

__loading_begin(__FILE__)

require 'down/chunked_io'

module Down

  # These additions make ChunkedIO look sufficiently "IO-like" to IOWindow
  # (defined by the 'archive-zip' gem) so that files uploaded to AWS S3 can be
  # processed by Archive::Zip::Entry#parse.
  #
  # === Implementation Notes
  # ChunkedIO does not care about 'lineno' (and neither does anything else in
  # the call chain of interest) so providing a dummy instance variable *should*
  # be harmless.
  #
  module ChunkedIOExt

    # Implement position setter.
    #
    # @return [Integer]
    #
    def pos=(value)
      seek(value, IO::SEEK_SET) unless pos == value
      pos
    end

    # Dummy method for IO-like behavior.
    #
    # @return [Integer]
    #
    def lineno
      @lineno ||= 0
    end

    # Dummy method for IO-like behavior.
    #
    # @return [Integer]
    #
    def lineno=(value)
      @lineno = value
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Down::ChunkedIO => Down::ChunkedIOExt

__loading_end(__FILE__)
