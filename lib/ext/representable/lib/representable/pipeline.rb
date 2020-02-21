# lib/ext/representable/lib/representable/pipeline.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Representable gem.

__loading_begin(__FILE__)

require 'representable/pipeline'

module Representable

  module CollectExt

    def call(input, options)
      # This make the parse a little more forgiving by allowing a simple string
      # to be interpreted as an implicit single-element array.
      super(Array.wrap(input), options)
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Representable::Collect => Representable::CollectExt

__loading_end(__FILE__)
