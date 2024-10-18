# lib/ext/sprockets/lib/sprockets/processor_utils.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for the Sprockets gem.

__loading_begin(__FILE__)

if DEBUG_SPROCKETS

  require 'sprockets/processor_utils'

  module Sprockets

    module ProcessorUtilsDebug

      include Sprockets::ExtensionDebugging

      # Non-functional hints for RubyMine type checking.
      # :nocov:
      unless ONLY_FOR_DOCUMENTATION
        include Sprockets::ProcessorUtils
      end
      # :nocov:

      # =======================================================================
      # :section: Sprockets::ProcessorUtils overrides
      # =======================================================================

      public

=begin # NOTE: Sprockets debugging
      def compose_processors(*processors)
        $stderr.puts "*** SPROCKETS [#{self}] Base #{__method__} override"
        #__ext_log(tag: "[#{self}] Base")
        super
      end
=end

      def call_processor(processor, input)
        #$stderr.puts "*** SPROCKETS [#{self}] Base #{__method__} override"
        #__ext_log(tag: "[#{self}] Base")
        t = ::DebugTiming.enter(processor, input)
        super
          .tap { ::DebugTiming.leave(processor, input, t) }
      end

    end

    override ProcessorUtils => ProcessorUtilsDebug

  end

end

__loading_end(__FILE__)
