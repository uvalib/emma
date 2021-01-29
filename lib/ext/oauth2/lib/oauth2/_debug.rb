# lib/ext/oauth2/lib/oauth2/_debug.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for OAuth2 gem extensions.

__loading_begin(__FILE__)

require 'oauth2'

module OAuth2

  module ExtensionDebugging

    include Emma::Debug::OutputMethods

    # Debug method for the including class.
    #
    # @param [String, Symbol] meth
    # @param [Array]          args
    # @param [Hash]           opt
    # @param [Proc]           block   Passed to #__debug_items.
    #
    # @return [nil]
    #
    def __oauth2_debug(meth, *args, **opt, &block)
      opt[:leader]      = "OAUTH2 #{__oauth2_debug_tag}"
      opt[:separator] ||= ' | '
      __debug_items(meth, *args, opt, &block)
    end

    private

    # Log output tag for the including class.
    #
    # @return [String]
    #
    def __oauth2_debug_tag
      self.class.name.remove(/^[^:]+::/)
    end

  end

end

__loading_end(__FILE__)
