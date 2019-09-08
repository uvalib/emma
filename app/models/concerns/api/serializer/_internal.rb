# app/models/concerns/api/serializer/_internal.rb
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

# This stub exists to satisfy the Zeitwerk loader.
module Api::Serializer::Internal; end

require 'representable'
require 'representable/json'
require 'representable/xml'
require 'representable/coercion'

# Set to *true* for debugging; set to *false* for normal operation.
DEBUG_REPRESENTABLE = false unless defined?(DEBUG_REPRESENTABLE)

module Representable

  module AppDebug

    if DEBUG_REPRESENTABLE

      LDR = '||| '
      SEP = ' // '

      def __debug(*args)
        opt = args.extract_options!
        args += Array.wrap(yield) if block_given?
        line = "#{LDR}#{args.shift}"
        if opt.present?
          line << SEP << opt.map { |k, v| "#{k} = #{v.inspect}" }.join(SEP)
        end
        if args.present?
          line << SEP << args.join(SEP)
        end
        __output(line)
      end

    else

      def __debug(*)
      end

    end

  end

  module CreateObject

    extend AppDebug

    remove_const(:Class) if const_defined?(:Class, false)

    # noinspection RubyConstantNamingConvention
    Class = ->(input, options) do
      binding = options[:binding]
      object_class = binding.evaluate_option(:class, input, options)
      __debug("Class #{object_class}", input: input, options: options)
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

      include AppDebug

      def read(hash, as)
        __debug("Hash.#{__method__}", as: as, hash: hash)
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

  if DEBUG_REPRESENTABLE

    extend AppDebug

    %i[
      AssignFragment
      ReadFragment
      Reader
      StopOnNotFound
      StopOnNil
      OverwriteOnNil
      Default
      SkipParse
      Deserializer
      Deserialize
      ParseFilter
      Setter
      SetValue
      Stop
      If
      StopOnExcluded
    ].each do |constant|
      remove_const(constant) if const_defined?(constant, false)
    end

    # noinspection RubyConstantNamingConvention
    AssignFragment = ->(input, options) do
      __debug('AssignFragment', input: input)
      options[:fragment] = input
    end

    # noinspection RubyConstantNamingConvention
    ReadFragment = ->(input, options) do
      __debug('ReadFragment', input: input)
      options[:binding].read(input, options[:as])
    end

    # noinspection RubyConstantNamingConvention
    Reader = ->(input, options) do
      __debug('Reader', input: input)
      options[:binding].evaluate_option(:reader, input, options)
    end

    # noinspection RubyConstantNamingConvention
    StopOnNotFound = ->(input, _options) do
      __debug('StopOnNotFound', input: input)
      Binding::FragmentNotFound == input ? Pipeline::Stop : input
    end

    # noinspection RubyConstantNamingConvention
    StopOnNil = ->(input, _options) do
      __debug('StopOnNil', input: input)
      input.nil? ? Pipeline::Stop : input
    end

    # noinspection RubyConstantNamingConvention
    OverwriteOnNil = ->(input, options) do
      __debug('OverwriteOnNil', input: input)
      input.nil? ? (SetValue.(input, options); Pipeline::Stop) : input
    end

    # noinspection RubyConstantNamingConvention
    Default = ->(input, options) do
      __debug('Default', input: input)
      Binding::FragmentNotFound == input ? options[:binding][:default] : input
    end

    # noinspection RubyConstantNamingConvention
    SkipParse = ->(input, options) do
      __debug('SkipParse', input: input)
      options[:binding].evaluate_option(:skip_parse, input, options) ? Pipeline::Stop : input
    end

    # noinspection RubyConstantNamingConvention
    Deserializer = ->(input, options) do
      __debug('Deserializer', input: input)
      options[:binding].evaluate_option(:deserialize, input, options)
    end

    # noinspection RubyConstantNamingConvention
    Deserialize = ->(input, args) do
      __debug('Deserialize', input: input)
      binding, fragment, options = args[:binding], args[:fragment], args[:options]

      # user_options:
      child_options = OptionsForNested.(options, args[:binding])

      input.send(binding.deserialize_method, fragment, child_options)
    end

    # noinspection RubyConstantNamingConvention
    ParseFilter = ->(input, options) do
      __debug('ParseFilter', input: input)
      options[:binding][:parse_filter].(input, options)
    end

    # noinspection RubyConstantNamingConvention
    Setter = ->(input, options) do
      __debug('Setter', input: input)
      options[:binding].evaluate_option(:setter, input, options)
    end

    # noinspection RubyConstantNamingConvention
    SetValue = ->(input, options) do
      __debug('SetValue', input: input)
      options[:binding]
        .send(:exec_context, options)
        .send(options[:binding].setter, input)
    end

    # noinspection RubyConstantNamingConvention
    Stop = ->(*) do
      __debug('Stop')
      Pipeline::Stop
    end

    # noinspection RubyConstantNamingConvention
    If = ->(input, options) do
      __debug('If', input: input)
      options[:binding].evaluate_option(:if, nil, options) ? input : Pipeline::Stop
    end

    # noinspection RubyConstantNamingConvention
    StopOnExcluded = ->(input, options) do
      __debug('StopOnExcluded', input: input, options: options)
      # noinspection RubyJumpError
      return input unless options[:options]
      # noinspection RubyJumpError
      # noinspection RubyAssignmentExpressionInConditionalInspection
      return input unless props = (options[:options][:exclude] || options[:options][:include])

      res = props.include?(options[:binding].name.to_sym)
      # false with include: Stop. false with exclude: go!

      # noinspection RubyJumpError
      return input if options[:options][:include]&&res
      # noinspection RubyJumpError
      return input if options[:options][:exclude]&&!res
      Pipeline::Stop
    end

    module CreateObject

      remove_const(:Instance) if const_defined?(:Instance, false)

      # noinspection RubyConstantNamingConvention
      Instance = ->(input, options) do
        __debug('Instance', input: input)
        options[:binding].evaluate_option(:instance, input, options) ||
          raise(DeserializeError.new(":instance did not return class constant for `#{options[:binding].name}`."))
      end

    end

    module Object

      class Binding

        include AppDebug

        def read(hash, as)
          __debug("Object.#{__method__}", as: as, hash: hash)
          fragment = hash.send(as) # :getter? no, that's for parsing!

          return FragmentNotFound if fragment.nil? and typed?
          fragment
        end

      end

    end

    module ForCollection

      include AppDebug

      def for_collection
        __debug("ForCollection.#{__method__}")
        # this is done at run-time, not a big fan of this. however, it saves us
        # from inheritance/self problems.
        @collection_representer ||= collection_representer!({})
        # DON'T make it inheritable as it would inherit the wrong singular.
      end

      private

      def collection_representer!(options)
        __debug("ForCollection.#{__method__}", options: options)
        singular = self

        # what happens here is basically
        # Module.new { include Representable::JSON::Collection; ... }
        nested_builder.(
          _base:     default_nested_class,
          _features: [singular.collection_representer_class],
          _block:    ->(*) { items options.merge(extend: singular) }
        ).tap do |result|
          __debug("ForCollection.#{__method__}", result: result)
        end
      end

      def collection_representer(options={})
        __debug("ForCollection.#{__method__}", options: options)
        @collection_representer = collection_representer!(options)
      end

    end

  end

end

__loading_end(__FILE__)
