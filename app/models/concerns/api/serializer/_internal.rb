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

require 'representable'
require 'representable/json'
require 'representable/xml'
require 'representable/coercion'

# Set to *true* for debugging; set to *false* for normal operation.
DEBUG_REPRESENTABLE = false

module Representable

  module CreateObject

    remove_const(:Class) if const_defined?(:Class, false)

    Class = ->(input, options) do
      binding = options[:binding]
      object_class = binding.evaluate_option(:class, input, options)
      if DEBUG_REPRESENTABLE
        $stderr.puts "||| Class #{object_class}" \
                     " // input   = #{input.inspect}" \
                     " // options = #{options.inspect}"
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

      def read(hash, as)
        if DEBUG_REPRESENTABLE
          $stderr.puts "||| Hash.#{__method__}" \
                       " // as = #{as.inspect}" \
                       " // hash = #{hash.inspect}"
        end
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

end

if DEBUG_REPRESENTABLE

  module Representable

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

    AssignFragment = ->(input, options) do
      $stderr.puts "||| AssignFragment // input = #{input.inspect}"
      options[:fragment] = input
    end

    ReadFragment = ->(input, options) do
      $stderr.puts "||| ReadFragment // input = #{input.inspect}"
      options[:binding].read(input, options[:as])
    end

    Reader = ->(input, options) do
      $stderr.puts "||| Reader // input = #{input.inspect}"
      options[:binding].evaluate_option(:reader, input, options)
    end

    StopOnNotFound = ->(input, _options) do
      $stderr.puts "||| StopOnNotFound // input = #{input.inspect}"
      Binding::FragmentNotFound == input ? Pipeline::Stop : input
    end

    StopOnNil = ->(input, _options) do
      $stderr.puts "||| StopOnNil // input = #{input.inspect}"
      input.nil? ? Pipeline::Stop : input
    end

    OverwriteOnNil = ->(input, options) do
      $stderr.puts "||| OverwriteOnNil // input = #{input.inspect}"
      input.nil? ? (SetValue.(input, options); Pipeline::Stop) : input
    end

    Default = ->(input, options) do
      $stderr.puts "||| Default // input = #{input.inspect}"
      Binding::FragmentNotFound == input ? options[:binding][:default] : input
    end

    SkipParse = ->(input, options) do
      $stderr.puts "||| SkipParse // input = #{input.inspect}"
      options[:binding].evaluate_option(:skip_parse, input, options) ? Pipeline::Stop : input
    end

    Deserializer = ->(input, options) do
      $stderr.puts "||| Deserializer // input = #{input.inspect}"
      options[:binding].evaluate_option(:deserialize, input, options)
    end

    Deserialize = ->(input, args) do
      $stderr.puts "||| Deserialize // input = #{input.inspect}"
      binding, fragment, options = args[:binding], args[:fragment], args[:options]

      # user_options:
      child_options = OptionsForNested.(options, args[:binding])

      input.send(binding.deserialize_method, fragment, child_options)
    end

    ParseFilter = ->(input, options) do
      $stderr.puts "||| ParseFilter // input = #{input.inspect}"
      options[:binding][:parse_filter].(input, options)
    end

    Setter = ->(input, options) do
      $stderr.puts "||| Setter // input = #{input.inspect}"
      options[:binding].evaluate_option(:setter, input, options)
    end

    SetValue = ->(input, options) do
      $stderr.puts "||| SetValue // input = #{input.inspect}"
      options[:binding]
        .send(:exec_context, options)
        .send(options[:binding].setter, input)
    end

    Stop = ->(*) do
      $stderr.puts "||| Stop"
      Pipeline::Stop
    end

    If = ->(input, options) do
      $stderr.puts "||| If // input = #{input.inspect}"
      options[:binding].evaluate_option(:if, nil, options) ? input : Pipeline::Stop
    end

    StopOnExcluded = ->(input, options) do
      $stderr.puts "\n\n||| StopOnExcluded" \
        " // input = #{input.inspect}" \
        " // options = #{options.inspect}"
      return input unless options[:options]
      return input unless props = (options[:options][:exclude] || options[:options][:include])

      res = props.include?(options[:binding].name.to_sym)
      # false with include: Stop. false with exclude: go!

      return input if options[:options][:include]&&res
      return input if options[:options][:exclude]&&!res
      Pipeline::Stop
    end

    module CreateObject

      remove_const(:Instance) if const_defined?(:Instance, false)

      Instance = ->(input, options) do
        $stderr.puts "||| Instance // input = #{input.inspect}"
        options[:binding].evaluate_option(:instance, input, options) ||
          raise(DeserializeError.new(":instance did not return class constant for `#{options[:binding].name}`."))
      end

    end

    module Object

      class Binding

        def read(hash, as)
          $stderr.puts "||| Object.read" \
                       " // as = #{as.inspect}" \
                       " // hash = #{hash.inspect}"
          fragment = hash.send(as) # :getter? no, that's for parsing!

          return FragmentNotFound if fragment.nil? and typed?
          fragment
        end

      end

    end

    module ForCollection

      def for_collection
        $stderr.puts "||| ForCollection.#{__method__}"
        # this is done at run-time, not a big fan of this. however, it saves us
        # from inheritance/self problems.
        @collection_representer ||= collection_representer!({})
        # DON'T make it inheritable as it would inherit the wrong singular.
      end

      private

      def collection_representer!(options)
        $stderr.puts "||| ForCollection.#{__method__}" \
                     " // options = #{options.inspect}"
        singular = self

        # what happens here is basically
        # Module.new { include Representable::JSON::Collection; ... }
        nested_builder.(
          _base:     default_nested_class,
          _features: [singular.collection_representer_class],
          _block:    ->(*) { items options.merge(:extend => singular) }
        ).tap do |result|
          $stderr.puts "||| ForCollection.#{__method__}" \
                       " // result = #{result.inspect}"
        end
      end

      def collection_representer(options={})
        $stderr.puts "||| ForCollection.#{__method__}" \
                     " // options = #{options.inspect}"
        @collection_representer = collection_representer!(options)
      end

    end

  end

end

__loading_end(__FILE__)
