# lib/emma/extension.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for Puma gem extensions.

__loading_begin(__FILE__)

require 'emma/debug'
require 'emma/time_methods'

module Emma::Extension

  # Common definitions for extended logging of gem overrides.
  #
  module Debugging

    module Methods

      include Emma::Debug::OutputMethods
      include Emma::TimeMethods

      EXT_LOG_SEPARATOR = ' | '
      EXT_LOG_LEADER    = LOG_TO_STDOUT ? '' : EXT_LOG_SEPARATOR.lstrip.freeze

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Debug method for the including class.
      #
      # @param [Array]       args
      # @param [String, nil] leader     Default: `#__ext_log_leader`.
      # @param [String, nil] tag        Default: `#__ext_log_tag`.
      # @param [String, nil] separator  Default: `#EXT_LOG_SEPARATOR`.
      # @param [Hash]        opt        Appended to *args* if present.
      #
      # @return [nil]
      #
      # @yield Generate additional parts.
      # @yieldreturn [Array, any] Appended to *args*.
      #
      #--
      # === Variations
      #++
      #
      # @overload __ext_log(meth, *args, leader: nil, tag: nil, separator: nil)
      #   Specify calling method.
      #   @param [Symbol]      meth
      #   @param [Array]       args
      #   @param [String, nil] leader
      #   @param [String, nil] tag
      #   @param [String, nil] separator
      #   @param [Hash]        opt
      #   @return [nil]
      #
      # @overload __ext_log(*args, leader: nil, tag: nil, separator: nil)
      #   Calling method defaults to `#calling_method`.
      #   @param [Array]       args
      #   @param [String, nil] leader
      #   @param [String, nil] tag
      #   @param [String, nil] separator
      #   @param [Hash]        opt
      #   @return [nil]
      #
      def __ext_log(*args, leader: nil, tag: nil, separator: nil, **opt)
        meth = args.first.is_a?(Symbol) ? args.shift : calling_method&.to_sym
        meth = 'NEW' if meth == :initialize
        ldr  = leader    || __ext_log_leader
        tag  = tag       || __ext_log_tag
        sep  = separator || EXT_LOG_SEPARATOR

        args.concat(Array.wrap(yield)) if block_given?
        if opt.present?
          opt = args.pop.merge(opt) if args.last.is_a?(Hash)
          args << opt
        end

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
      # @param [Array] args
      # @param [Hash]  opt            Passed to #__debug_items.
      # @param [Proc]  blk            Passed to #__debug_items.
      #
      # @option opt [String, nil] :leader     Default: `#__ext_log_leader`.
      # @option opt [String, nil] :tag        Default: `#__ext_log_tag`.
      # @option opt [String]      :separator  Default: `#EXT_LOG_SEPARATOR`.
      #
      # @return [nil]
      #
      #--
      # === Variations
      #++
      #
      # @overload __ext_debug(meth, *args, tag:, **opt, &blk)
      #   Specify calling method.
      #   @param [Symbol] meth
      #   @param [Array]  args
      #   @param [Hash]   opt
      #   @param [Proc]   blk
      #   @return [nil]
      #
      # @overload __ext_debug(*args, tag:, &blk)
      #   Calling method defaults to `#calling_method`.
      #   @param [Array]  args
      #   @param [Hash]   opt
      #   @param [Proc]   blk
      #   @return [nil]
      #
      def __ext_debug(*args, **opt, &blk)
        meth = args.first.is_a?(Symbol) ? args.shift : calling_method&.to_sym
        meth = 'NEW' if meth == :initialize
        ldr  = (opt.delete(:leader) || __ext_log_leader)&.strip
        tag  = (opt.delete(:tag)    || __ext_log_tag)&.strip

        args.map! do |arg|
          arg.is_a?(Float) ? time_span(arg) : arg
        end

        opt[:leader]      = [ldr, tag].compact.join(' ')
        opt[:separator] ||= EXT_LOG_SEPARATOR
        __debug_items(meth, *args, **opt, &blk)
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
        self_class.name || '???'
      end

    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.include(Methods)
      base.extend(Methods)
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
      base.include(Methods)
      base.extend(Methods)
    end

  end

end

__loading_end(__FILE__)
