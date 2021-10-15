# lib/emma/extension.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for Puma gem extensions.

__loading_begin(__FILE__)

require 'emma/debug'
require 'emma/time'

module Emma::Extension

  # Common definitions for extended logging of gem overrides.
  #
  module Debugging

    module Methods

      include Emma::Debug::OutputMethods
      include Emma::Time

      EXT_LOG_SEPARATOR = ' | '
      EXT_LOG_LEADER    = EXT_LOG_SEPARATOR.lstrip.freeze

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Debug method for the including class.
      #
      # @param [Array] args
      #
      # @option args[-1] [String, nil] :leader     Def: `#__ext_log_leader`.
      # @option args[-1] [String, nil] :tag        Def: `#__ext_log_tag`.
      # @option args[-1] [String]      :separator  Def: `#EXT_LOG_SEPARATOR`.
      #
      # @yield Generate additional parts.
      # @yieldreturn [Array] Appended to *args*.
      #
      # @return [nil]
      #
      #--
      # == Variations
      #++
      #
      # @overload __ext_log(meth, *args, tag:, &block)
      #   @param [Symbol] meth        Calling method
      #   @param [Array]  args
      #   @return [nil]
      #
      # @overload __ext_log(*args, tag:, &block)
      #   @param [Array]  args
      #   @return [nil]
      #
      def __ext_log(*args)
        meth = args.first.is_a?(Symbol) ? args.shift : calling_method&.to_sym
        meth = 'NEW' if meth == :initialize
        opt  = args.last.is_a?(Hash) ? args.pop.dup : {}
        ldr  = opt.key?(:leader) ? opt.delete(:leader) : __ext_log_leader
        tag  = opt.key?(:tag)    ? opt.delete(:tag)    : __ext_log_tag
        sep  = (opt.delete(:separator) || EXT_LOG_SEPARATOR)

        args << opt if opt.present?
        args += Array.wrap(yield) if block_given?

        part  = []
        part << [ldr, tag].compact.join(' ')
        part << meth
        args.each do |a|
          case a
            when Hash      then part += a.map { |k, v| "#{k} = #{v.inspect}" }
            when Exception then part << "#{a.class} - #{a.message.inspect}"
            when Float     then part << time_span(a)
            else                part << a
          end
        end
        Log.debug { part.compact.join(sep) }

      rescue => error
        __debug_exception("#{__ext_class} #{__method__}", error)
        raise error
      end

      # Debug method for the including class.
      #
      # @param [Array]          args
      # @param [Hash]           opt
      # @param [Proc]           block   Passed to #__debug_items.
      #
      # @option opt [String, nil] :leader     Default: `#__ext_log_leader`.
      # @option opt [String, nil] :tag        Default: `#__ext_log_tag`.
      # @option opt [String]      :separator  Default: `#EXT_LOG_SEPARATOR`.
      #
      # @return [nil]
      #
      #--
      # == Variations
      #++
      #
      # @overload __ext_debug(meth, *args, tag:, **opt, &block)
      #   @param [Symbol]      meth   Calling method
      #   @param [Array]       args
      #   @param [Hash]        opt
      #   @param [Proc]        block  Passed to #__debug_items.
      #   @return [nil]
      #
      # @overload __ext_log(*args, tag:, &block)
      #   @param [Array]       args
      #   @param [Hash]        opt
      #   @param [Proc]        block  Passed to #__debug_items.
      #   @return [nil]
      #
      def __ext_debug(*args, **opt, &block)
        meth = args.first.is_a?(Symbol) ? args.shift : calling_method&.to_sym
        meth = 'NEW' if meth == :initialize
        ldr  = (opt.delete(:leader) || __ext_log_leader)&.strip
        tag  = (opt.delete(:tag)    || __ext_log_tag)&.strip

        args.map! do |arg|
          arg = time_span(arg) if arg.is_a?(Float)
          arg
        end

        opt[:leader]      = [ldr, tag].compact.join(' ')
        opt[:separator] ||= EXT_LOG_SEPARATOR
        __debug_items(meth, *args, opt, &block)
      end

      # =======================================================================
      # :section:
      # =======================================================================

      protected

      # Log output tag for the extended gem.
      #
      # @param [String, nil] tag      Default: 'EXT'.
      #
      # @return [String]
      #
      def __ext_log_leader(tag = nil)
        tag = tag&.to_s&.strip || 'EXT'
        "#{EXT_LOG_LEADER}#{tag}"
      end

      # Log output tag for the including class.
      #
      # @return [String]
      #
      def __ext_log_tag
        __ext_class.remove(/^[^:]+::/)
      end

      # Name of the including class.
      #
      # @return [String]
      #
      def __ext_class
        self.is_a?(Class) && name || self.class.name || '???'
      end

    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:include, Methods)
      base.send(:extend,  Methods)
    end

  end

  # Include to provide stubs for the methods defined in Debugging.
  #
  module NoDebugging

    module Methods

      include Debugging::Methods

      neutralize(*public_instance_methods(false))

    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:include, Methods)
      base.send(:extend,  Methods)
    end

  end

end

__loading_end(__FILE__)
