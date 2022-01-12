# lib/ext/representable/lib/representable/obj.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Representer for a plain Ruby Hash object.

__loading_begin(__FILE__)

require 'representable/hash'

module Representable

  # Represent a Ruby (hash) object.
  module Obj

    extend  Representable::Hash::ClassMethods
    include Representable::Hash

    include Emma::Json

    # =========================================================================
    # :section:
    # =========================================================================

    public

    module ClassMethods
      include Representable::Hash::ClassMethods
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create a (hash) object from a serialized Ruby hash (or JSON).
    #
    # @param [String] data
    # @param [Array]  args            To Representable::Hash#from_hash
    #
    # @return [Hash]
    #
    def from_obj(data, *args)
      hash = hash_parse(data)
      from_hash(hash, *args)
    end

    # Serialize a (hash) object into a representation of a Ruby (hash) object.
    #
    # @param [Array] args             To Representable::Hash#to_hash
    #
    # @return [String]
    #
    def to_obj(*args)
      $stderr.puts "................... Representable::Obj.to_obj | #{args.inspect}" # TODO: remove
      opt  = args.last.is_a?(::Hash) ? args.pop : {}
      hash = to_hash(*args)
      hash_render(hash, **opt)
    end

    alias_method :parse,  :from_obj
    alias_method :render, :to_obj

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.class_eval do
        include Representable
        extend  ClassMethods
        register_feature Representable::Obj
      end
      base
    end
  end

end

__loading_end(__FILE__)
