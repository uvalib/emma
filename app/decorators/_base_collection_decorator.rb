# app/decorators/model_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common base for collection decorator classes.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Model>]
#
class BaseCollectionDecorator < Draper::CollectionDecorator

  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include BaseCollectionDecorator::Fields
    include BaseCollectionDecorator::Form
    include BaseCollectionDecorator::Hierarchy
    include BaseCollectionDecorator::Links
    include BaseCollectionDecorator::List
    include BaseCollectionDecorator::Menu
    include BaseCollectionDecorator::Table
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods for each collection decorator class instance.
  #
  # @!attribute [r] object_class
  #   @return [Class]
  #
  module InstanceMethods

    include BaseDecorator::InstanceMethods

    # =========================================================================
    # :section: Object overrides
    # =========================================================================

    public

    # Modify the inspection to limit the size of individual member results.
    #
    # @param [Integer] max            Maximum characters per member.
    #
    # @return [String]
    #
    def inspect(max: 256)
      items = Array.wrap(object).map(&:class)
      items = items.tally.map { |cls, cnt| "#{cnt} #{cls}" }.presence
      items = items&.join(' / ') || 'empty'
      vars  =
        (instance_variables - %i[@object]).map { |var|
          [var, instance_variable_get(var).inspect.truncate(max)]
        }.to_h
      vars  = vars.merge!('@object': "(#{items})").map { |k, v| "#{k}=#{v}" }
      "#<#{self.class.name}:#{object_id} %s>" % vars.join(' ')
    end

  end

  # Methods for each collection decorator class.
  #
  module ClassMethods

    include BaseDecorator::ClassMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The decorator class for list elements.
    #
    # @return [Class]
    #
    def decorator_class
      @decorator_class
    end

    # The Draper::Decorator#object_class for list elements.
    #
    # @return [Class]
    #
    def object_class
      decorator_class&.object_class || super
    end

  end

  module Common
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  include Common

  # ===========================================================================
  # :section: Draper::CollectionDecorator overrides
  # ===========================================================================

  public

  # @private
  DEFAULT_ACTION = :index

  # initialize
  #
  # @param [Any, nil] obj
  # @param [Hash]     opt
  #
  def initialize(obj = nil, **opt)
    obj  = Array.wrap(obj)
    with = opt.delete(:with) || self.class.decorator_class
    ctx  = initialize_context(**opt).reverse_merge!(action: DEFAULT_ACTION)
    # noinspection RubyMismatchedArgumentType
    super(obj, with: with, context: ctx)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Set to *true* to see how each collection decorator overrides Array methods.
  #
  # @type [Boolean]
  #
  # @see BaseDecorator#DEBUG_DECORATOR_INHERITANCE
  #
  DEBUG_COLLECTION_INHERITANCE = false

  # Define the association between a collection decorator and the decorator
  # for its elements.
  #
  # This also causes the element decorator's Common module to be included so
  # that the collection decorator acquires the same definitions.
  #
  # @param [Class] base
  #
  # @return [void]
  #
  #--
  # noinspection RbsMissingTypeSignature
  #++
  def self.collection_of(base)
    unless base.is_a?(Class) && (base < BaseDecorator)
      raise 'Indicate the BaseDecorator subclass for list elements'
    end
    @decorator_class = base
    @model_type      = @decorator_class.model_type
    definitions      = "#{base}::Common".safe_constantize
    include(definitions) if definitions.is_a?(Module)
    debug_inheritance    if DEBUG_COLLECTION_INHERITANCE
  end

end

__loading_end(__FILE__)
