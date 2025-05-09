# app/models/concerns/serializable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This is a mixin for any class that wants to define its own custom ActiveJob
# serializer/deserializer.
#
module Serializable

  extend ActiveSupport::Concern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # These overrides (in part) work around deficiencies in the standard
  # definition of ActiveJob custom serializers to allow:
  #
  # * The ability for a subclasses in a hierarchy of class definitions to have
  #   their own serializers.
  #
  # * The ability for items requiring custom serializer support to be nested.
  #
  # @see ActiveJob::ArgumentsExt
  #
  class Base < ActiveJob::Serializers::ObjectSerializer

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @type [String,Symbol]
    VALUE_KEY = :value

    # @type [Array<String,Symbol>]
    VALUE_KEYS = [VALUE_KEY.to_s, VALUE_KEY.to_sym].freeze

    # @type [Array<String,Symbol>]
    RESERVED_KEYS = ActiveJob::Arguments.const_get(:RESERVED_KEYS).freeze

    # The value here is from ActiveJob::Arguments::PERMITTED_TYPES which was
    # removed in Rails 7.1.3.
    #
    # @type [Array<Module>]
    #
    PERMITTED_TYPES =
      [NilClass, String, Integer, Float, TrueClass, FalseClass].freeze

    # @type [Array<Module>]
    ENUMERABLE_TYPES = [Hash, Array].freeze

    # @type [Array<Module>]
    OTHER_TYPES = [
      ActiveSupport::HashWithIndifferentAccess,
      GlobalID::Identification
    ].freeze

    # @type [Array<Module>]
    WORK_REQUIRED = (ENUMERABLE_TYPES + OTHER_TYPES).freeze

    # @type [Array<Module>]
    BASIC_TYPES = (PERMITTED_TYPES + ENUMERABLE_TYPES + OTHER_TYPES).freeze

    # =========================================================================
    # :section: ActiveJob::Serializers::ObjectSerializer overrides
    # =========================================================================

    public

    # The default method is inadequate for serializers defined for a hierarchy
    # of subclasses because it will always return with the serializer
    # associated with the base class of that hierarchy rather than the
    # serializer for the specific subclass.
    #
    # @param [any, nil] argument
    #
    def serialize?(argument)
      argument.class == klass
    end

    # To be consistent, serialized values will always be rooted at the same
    # place in the serialization hash.
    #
    # @param [any, nil] item
    #
    # @return [Hash]
    #
    # @yield [item] Return data from *item* that will be needed to recreate it.
    # @yieldparam [self] item An instance of the class.
    # @yieldreturn [any, nil] The data from *item*.
    #
    def serialize(item)
      item = yield(item)              if block_given?
      item = item.to_h                unless BASIC_TYPES.include?(item.class)
      item = serialize_argument(item) if WORK_REQUIRED.include?(item.class)
      super(VALUE_KEY => item)
    end

    # Recreate an item from the data produced by #serialize.
    #
    # @param [Hash] hash        Generated via serialization.
    #
    # @return [any, nil]        An instance of the associated class.
    #
    # @yield [value]
    # @yieldparam [any,nil] value Data produced by #serialize.
    # @yieldreturn [self,any,nil] An item instance or data to create a new one.
    #
    def deserialize(hash)
      item = hash.values_at(*VALUE_KEYS).first
      item = deserialize_argument(item) if WORK_REQUIRED.include?(item.class)
      item = yield(item)                if block_given?
      item.is_a?(klass) ? item : klass.new(item)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    module Methods

      # =======================================================================
      # :section:
      # =======================================================================

      public

      def serialize_argument(item)
        ActiveJob::Arguments.send(__method__, item)
      end

      def deserialize_argument(item)
        ActiveJob::Arguments.send(__method__, item)
      end

      # Deep symbolize all keys except for ActiveJob reserved keys.
      #
      # @return [Hash{String,Symbol=>any,nil}]
      #
      def re_symbolize_keys(hash)
        hash.deep_transform_keys do |key|
          RESERVED_KEYS.include?(key) ? key.to_s : (key.try(:to_sym) || key)
        end
      end

      # =======================================================================
      # :section:
      # =======================================================================

      private

      def self.included(base)
        __included(base, self)
        base.extend(self)
      end

    end

    include Methods

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  THIS_MODULE = self

  class_methods do

    __included(self, THIS_MODULE)

    include Serializable::Base::Methods

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # Create a job serializer class associated with *base*.
    #
    # @param [Class] base   The executing class.
    #
    # @return [Class]       The serializer within the `base.class` namespace.
    # @return [nil]         If there was a problem.
    #
    def serializer_class(base = nil)
      base ||= self_class
      serializer = base.safe_const_get(:Serializer, false)
      unless serializer
        base.class_eval <<~HERE_DOC
          class #{base.name}::Serializer < Serializable::Base
            def klass
              #{base.name}
            end
          end
        HERE_DOC
        serializer = base.safe_const_get(:Serializer, false)
        # noinspection RubyResolve
        Rails.configuration.active_job.tap do |cfg|
          # NOTE: Under normal circumstances custom_serializers will
          #   already exist.  This extra check is just for the sake of
          #   executing a single file via "rails runner" from the desktop.
          cfg.custom_serializers ||= []
          cfg.custom_serializers << serializer
        end if serializer
      end
      serializer
    end

    # Serializer definition.
    #
    # @param [Symbol, nil] mode
    #
    #--
    # === Variations
    #++
    #
    # @overload serializer
    #   With no parameters or block, the statement just creates the serializer
    #   for the executing class.
    #
    # @overload serializer(mode = :serialize, &blk)
    #   Define a #serialize override to pass the block to Base#serialize.
    #   @param [Symbol] mode
    #   @param [Proc]   blk           Passed to Base#serialize.
    #
    # @overload serializer(mode = :deserialize, &blk)
    #   Define a #deserialize override to pass the block to Base#deserialize.
    #   @param [Symbol] mode
    #   @param [Proc]   blk           Passed to Base#serialize.
    #
    def serializer(mode = nil, &blk)
      serializer_class.tap do |serializer|
        case (mode &&= mode.to_sym)
          when :serialize, :deserialize
            serializer.define_method(mode) { |arg| super(arg, &blk ) }
          when nil
            Log.warn("#{self}.#{__method__}: block ignored") if blk
          else
            Log.warn("#{self}.#{__method__}: #{mode.inspect}: unexpected")
        end
      end
    end

  end

end

__loading_end(__FILE__)
