# lib/ext/representable/lib/representable.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Serialization is based on the 'representable' gem, with support from the
# 'virtus' gem for type-casting.
#
# == Implementation Notes
#
# Several adjustments were required:
#
# Representable::CreateObject#Class, the anonymous function which is part of
# the de-serialization pipeline, was redefined in order to allow nested objects
# to acquire information about the type of serializer they should be using.
#
# Representable::Hash::Binding#read was redefined in order to allow derivatives
# of Api::Message with :has_many properties to be de-serialized from JSON.

__loading_begin(__FILE__)

require 'representable/json'
require 'representable/xml'
require 'representable/coercion'

# Set internal debugging of Representable pipeline actions.
#
# - *false* for normal operation
# - *true*  for full debugging
# - :input  for debugging parsing/de-serialization.
# - :output for debugging rendering/serialization.
#
# @type [Boolean, Symbol]
#
DEBUG_REPRESENTABLE =
  ENV.fetch('DEBUG_REPRESENTABLE', false).then do |v|
    case (v.is_a?(String) ? (v = v.strip.downcase) : v)
      when *TRUE_VALUES  then true
      when *FALSE_VALUES then false
      when String        then v.sub(/^:/, '').to_sym
      else                    v
    end
  end

module Representable

  # Overrides adding extra debugging around method calls.
  #
  module RepresentableDebug

    # @private
    def self.included(base)
      base.send(:extend, self)
    end

    private

    # noinspection RubyMismatchedArgumentType
    if not DEBUG_REPRESENTABLE

      def __debug_show(*);   end
      def __debug_lambda(*); end
      def __debug_method(*); end

    else

      DEBUG_MODES = [:input, :output, true, false, nil]
      DEBUG_REPRESENTABLE.tap do |value|
        raise "invalid: #{value.inspect}" unless DEBUG_MODES.include?(value)
      end

      DEBUG_INPUT  = [:input,  true].include?(DEBUG_REPRESENTABLE)
      DEBUG_OUTPUT = [:output, true].include?(DEBUG_REPRESENTABLE)

      LEADER    = '||| '
      SEPARATOR = ' // '

      # __debug_show
      #
      # @param [Symbol, Any, nil] mode
      # @param [Array]            args
      # @param [Hash]             opt
      #
      # @return [nil]
      #
      # @yield To supply additional items to show.
      # @yieldreturn [Array, Any]
      #
      #--
      # == Variations
      #++
      #
      # @overload __debug_show(mode, *args, **opt)
      #   @param [Symbol, nil] mode        Either :input, :output or *nil*
      #   @param [Array]       args
      #   @param [Hash]        opt
      #
      # @overload __debug_show(*args, **opt)
      #   @param [Array]       args
      #   @param [Hash]        opt
      #
      # @see #__output_impl
      #
      #--
      # noinspection RubyMismatchedArgumentType
      #++
      def __debug_show(mode, *args, **opt)
        mode =
          case mode
            when :input  then 'I' if DEBUG_INPUT
            when :output then 'O' if DEBUG_OUTPUT
            when Symbol  then '-'.tap { args.unshift(mode) }
            else              '-'
          end
        return if mode.blank?
        args += Array.wrap(yield) if block_given?
        line  = +"#{LEADER}#{mode} #{args.shift}"
        items =
          opt.map do |k, v|
            if (k == :options) && v[:represented].present?
              {
                represented: v[:represented]
                               .class,
                options:     v[:options]
                               .except(:doc, :represented, :decorator)
                               .inspect,
              }.map { |k0, v0| "#{k0} = #{v0}" }.join(', ')
            elsif v.class.to_s.end_with?('Serializer')
              "#{k} = #{v}"
            else
              "#{k} = #{v.inspect}"
            end
          end
        items += args
        line << SEPARATOR << items.join(SEPARATOR) if items.present?
        __output_impl(line)
      end

      # Override one or more lambdas in order to "inject" a debug statement
      # before invoking the original definition.
      #
      # If *mode* is not compatible with the value of #DEBUG_REPRESENTABLE then
      # no overrides are performed.
      #
      # @param [Symbol, Any, nil] mode
      # @param [Array<Symbol>]    constants
      #
      # @return [nil]
      #
      #--
      # == Variations
      #++
      #
      # @overload __debug_lambda(mode, *constants)
      #   @param [Symbol, nil]   mode        Either :input, :output or *nil*
      #   @param [Array<Symbol>] constants
      #
      # @overload __debug_lambda(*constants)
      #   @param [Array<Symbol>] constants
      #
      # @see #__debug_show
      #
      #--
      # noinspection RubyMismatchedArgumentType
      #++
      def __debug_lambda(mode, *constants)
        if mode == :input
          return unless DEBUG_INPUT
        elsif mode == :output
          return unless DEBUG_OUTPUT
        else
          constants.unshift(mode) if mode.is_a?(Symbol)
          mode = nil
        end
        constants.flatten.each do |constant|
          unless const_defined?(constant, false)
            Log.warn "Representable.#{constant} not defined (skipped)"
            next
          end
          module_eval do
            const_set :"Original#{constant}", remove_const(constant)
            const_set constant, ->(input, options) do
              __debug_show(mode, constant, input: input, options: options)
              original_lambda = const_get(:"Original#{constant}", false)
              original_lambda.call(input, options).tap do |result|
                if result && (result != input)
                  __debug_show(mode, constant, 'return -->' => result.inspect)
                end
              end
            end
          end
        end
        nil
      end

      # Override one or more methods in order to "inject" a debug statement
      # before invoking the original definition.
      #
      # If *mode* is not compatible with the value of #DEBUG_REPRESENTABLE then
      # no overrides are performed.
      #
      # @param [Symbol, Any, nil] mode
      # @param [String, nil]      label
      # @param [Array<Symbol>]    methods
      #
      # @return [nil]
      #
      #--
      # == Variations
      #++
      #
      # @overload __debug_method(mode, label, *methods)
      #   @param [Symbol, nil]   mode        Either :input, :output or *nil*
      #   @param [String]        label
      #   @param [Array<Symbol>] methods
      #
      # @overload __debug_method(label, *methods)
      #   @param [String]        label
      #   @param [Array<Symbol>] methods
      #
      # @see #__debug_show
      #
      #--
      # noinspection RubyMismatchedArgumentType
      #++
      def __debug_method(mode, label, *methods)
        if mode == :input
          return unless DEBUG_INPUT
        elsif mode == :output
          return unless DEBUG_OUTPUT
        elsif mode.is_a?(String)
          methods.unshift(label)
          label = mode
          mode  = nil
        else
          mode  = nil
        end
        if label.is_a?(Symbol)
          methods.unshift(label)
          label = nil
        end
        label &&= "#{label}."
        methods.flatten.each do |meth|
          module_eval do
            alias_method :"original_#{meth}", meth
            define_method(meth) do |*args|
              __debug_show(mode, "#{label}#{meth}", *args)
              send("original_#{meth}", *args)
            end
          end
        end
        nil
      end

    end

  end

end

module Representable

  module CreateObject

    include RepresentableDebug

    remove_const(:Class) if const_defined?(:Class, false)

    #--
    # noinspection RubyConstantNamingConvention
    #++
    Class = ->(input, options) do
      binding = options[:binding]
      object_class = binding.evaluate_option(:class, input, options)
      __debug_show(:input, input: input, options: options) do
        "Class #{object_class}"
      end
      unless object_class
        raise DeserializeError,
          ":class did not return class constant for `#{binding.name}`."
      end
      format = binding.to_s.match?(/::Xml/i) ? :xml : :json
      object_class.new(nil, format: format)
    end

  end

  module Hash

    class Binding

      include RepresentableDebug

      def read(hash, as)
        __debug_show(:input, as: as, hash: hash) { "Hash.#{__method__}" }
        if hash.is_a?(Array)
          hash
        elsif hash.key?(as)
          hash[as]
        else
          FragmentNotFound
        end
      end

    end

  end

  module JSON

    def to_json(*args)
      opt = args.last.is_a?(::Hash) ? args.pop : {}
      obj = to_hash(*args)
      MultiJson.dump(obj, opt)
    end

  end

  # The "render pipeline" for the Representable gem defines this filter so that
  # the default for a property is returned if it is deemed to be skippable.
  # While that might be reasonable when parsing to de-serialize a message, it's
  # unexpected when serializing to generate a message.
  #
  # Since this method is not used when parsing, it can be safely redefined.

  remove_const(:RenderDefault)

  # noinspection RubyConstantNamingConvention
  RenderDefault = ->(input, options) do
    input unless options[:binding].skipable_empty_value?(input)
  end

  if DEBUG_REPRESENTABLE

    include RepresentableDebug

    # =========================================================================
    # :section: representable/deserializer.rb replacements
    # =========================================================================

    __debug_lambda(:input, %i[
      AssignFragment
      ReadFragment
      Reader
      OverwriteOnNil
      Default
      SkipParse
      Deserializer
      Deserialize
      ParseFilter
      Setter
      SetValue
    ])

    __debug_lambda(%i[
      StopOnNotFound
      StopOnNil
      Stop
      If
      StopOnExcluded
    ])

    module CreateObject

      include RepresentableDebug

      __debug_lambda(:input, :Instance)

    end

    # =========================================================================
    # :section: representable/serializer.rb replacements
    # =========================================================================

    __debug_lambda(:output, %i[
      Getter
      GetValue
      Reader
      Writer
      RenderDefault
      StopOnSkipable
      RenderFilter
      SkipRender
      Serializer
      Serialize
      WriteFragment
    ])

    __debug_lambda(%i[
      As
      AssignAs
      AssignName
    ])

    # =========================================================================
    # :section: Other replacements
    # =========================================================================

    module Object

      class Binding

        include RepresentableDebug

        __debug_method(:input, 'Object', :read)

      end

    end

    module ForCollection

      include RepresentableDebug

      __debug_method('ForCollection', %i[
        for_collection
        collection_representer!
        collection_representer
      ])

    end

  end

end

__loading_end(__FILE__)
