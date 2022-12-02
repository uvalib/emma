# lib/ext/sprockets/lib/sprockets/sassc_processor.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debug timing of SassC (if loaded).

__loading_begin(__FILE__)

if DEBUG_SPROCKETS && Gem.loaded_specs['sassc'].present?

  require 'sprockets/sassc_processor'

  module Sprockets

    module SasscProcessorDebug

      include Sprockets::ExtensionDebugging

      # =======================================================================
      # :section: Sprockets::SasscProcessor overrides
      # =======================================================================

      public

      def call(input)
        $stderr.puts "*** SasscProcessor override [#{self}]"
        #__ext_log("SasscProcessor override [#{self}]")
        super
      end

    end

    override SasscProcessor => SasscProcessorDebug

  end

  # noinspection RubyResolve
  require 'sassc-rails'

  module SassC

    module EngineExt

      def render
        $stderr.puts "*** SASS #{__method__} override [#{self}]"
        t = ::DebugTiming.enter(self, {})
        super
          .tap { ::DebugTiming.leave(self, {}, t) }
      end

    end

    override Engine => EngineExt

  end

  module SassC::Rails

    module SassTemplateExt

      def call(input)
        $stderr.puts "*** SASS #{__method__} override [#{self}]"
        t = ::DebugTiming.enter(self, {})
        super
          .tap { ::DebugTiming.leave(self, {}, t) }
      end

    end

    # noinspection RubyResolve
    override SassTemplate => SassTemplateExt

  end

end

__loading_end(__FILE__)
