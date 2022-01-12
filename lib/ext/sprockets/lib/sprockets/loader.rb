# lib/ext/sprockets/lib/sprockets/loader.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for the Sprockets gem.

__loading_begin(__FILE__)

if DEBUG_SPROCKETS

  require_relative 'processor_utils'
  require 'sprockets/loader'

  module Sprockets

    module LoaderDebug

      include Sprockets::ExtensionDebugging
      include Sprockets::ProcessorUtilsDebug if RUBY_VERSION < '3'

      # Non-functional hints for RubyMine type checking.
      unless ONLY_FOR_DOCUMENTATION
        # :nocov:
        include Sprockets::Loader
        # :nocov:
      end

      # =======================================================================
      # :section: Sprockets::Loader overrides
      # =======================================================================

      public

=begin
      def load(uri)
        __ext_log(uri.inspect, tag: "[#{self}] Loader")
        super
      end
=end

      def load_from_unloaded(unloaded)
        data  = unloaded.try(:uri) || unloaded
        input = { filename: data }
        #__ext_log(data.inspect, tag: "[#{self}] Loader")
        t = ::DebugTiming.enter(__method__, input)
        super
          .tap { ::DebugTiming.leave(__method__, input, t) }
      end

    end

    override Loader => LoaderDebug

  end

end

__loading_end(__FILE__)
