# lib/ext/down/lib/down/chunked_io.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Down gem.

__loading_begin(__FILE__)

require 'down/chunked_io'

module Down

  module ChunkedIOExt

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Implement position setter.
    #
    # @return [Integer]
    #
    def pos=(value)
      seek(value, IO::SEEK_SET) unless pos == value
      pos
    end

    # Dummy method for IO-like behavior; ChunkedIO does not care about this.
    #
    # @return [Integer]
    #
    def lineno
      @lineno ||= 0
    end

    # Dummy method for IO-like behavior; ChunkedIO does not care about this.
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
