# lib/ext/sprockets/lib/sprockets/base.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for the Sprockets gem.

__loading_begin(__FILE__)

if DEBUG_SPROCKETS

  require_relative 'loader'
  require 'sprockets/base'

  module Sprockets

    module BaseDebug

      include Sprockets::ExtensionDebugging
      include Sprockets::LoaderDebug if RUBY_VERSION < '3'

      # =======================================================================
      # :section: Sprockets::Base overrides
      # =======================================================================

      public

      def find_asset(*args, **options)
        info = args.inspect
        $stderr.puts "*** SPROCKETS [#{self}] Base #{__method__} | #{info}"
        #__ext_log(info, tag: "[#{self}] Base")
        super
      end

      def find_asset!(*args)
        info = args.inspect
        $stderr.puts "*** SPROCKETS [#{self}] Base #{__method__} | #{info}"
        #__ext_log(info, tag: "[#{self}] Base")
        super
      end

      def find_all_linked_assets(*args, &blk)
        info = args.inspect
        $stderr.puts "*** SPROCKETS [#{self}] Base #{__method__} | #{info}"
        #__ext_log(info, tag: "[#{self}] Base")
        super(*args, &blk)
      end

    end

    override Base => BaseDebug

  end

end

__loading_end(__FILE__)
