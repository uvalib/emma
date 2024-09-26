# app/decorators/model_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common base for collection decorator classes.
#
class BaseCollectionDecorator < Draper::CollectionDecorator

  include BaseCollectionDecorator::Common
  include BaseCollectionDecorator::Configuration
  include BaseCollectionDecorator::Controls
  include BaseCollectionDecorator::Downloads
  include BaseCollectionDecorator::Fields
  include BaseCollectionDecorator::Form
  include BaseCollectionDecorator::Grid
  include BaseCollectionDecorator::Helpers
  include BaseCollectionDecorator::Hierarchy
  include BaseCollectionDecorator::Links
  include BaseCollectionDecorator::List
  include BaseCollectionDecorator::Lookup
  include BaseCollectionDecorator::Menu
  include BaseCollectionDecorator::Pagination
  include BaseCollectionDecorator::Row
  include BaseCollectionDecorator::Submission
  include BaseCollectionDecorator::Table

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Methods for each collection decorator class instance.
  #
  module SharedInstanceMethods

    include BaseDecorator::SharedInstanceMethods

    # =========================================================================
    # :section: Object overrides
    # =========================================================================

    public

    # Modify the inspection to limit the size of individual element results.
    #
    # @param [Integer] max            Maximum characters per element.
    #
    # @return [String]
    #
    def inspect(max: 256)
      items = Array.wrap(object).map(&:class)
      items = items.tally.map { |cls, cnt| "#{cnt} #{cls}" }.presence
      items = items&.join(' / ') || 'empty'
      vars  =
        instance_variables.excluding(:@object).map { |var|
          [var, instance_variable_get(var).inspect.truncate(max)]
        }.to_h
      vars  = vars.merge!('@object': "(#{items})").map { "#{_1}=#{_2}" }
      "#<#{self.class.name}:#{object_id} %s>" % vars.join(' ')
    end

    # Create a value for #context based on the parameters supplied through the
    # initializer.
    #
    # @param [Hash] opt
    #
    # @return [Hash]                  Suitable for assignment to #context.
    #
    # @see #MODEL_TABLE_DATA_OPT
    #
    def initialize_context(**opt)
      super.tap do |ctx|
        pag = ctx[:paginator]
        if ctx[:partial].is_a?(TrueClass)
          ctx[:partial] = pag ? pag.page_size : Paginator.default_page_size
        end
        ctx[:pageable] = !ctx[:partial] unless ctx.key?(:pageable)
        ctx[:sortable] = true           unless ctx.key?(:sortable)
        pag&.no_pagination              if false?(ctx[:pageable])
      end
    end

  end

  # Methods for each collection decorator class.
  #
  module SharedClassMethods

    include BaseDecorator::SharedClassMethods

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

  # Used by BaseCollectionDecorator#collection_of to supply shared definitions
  # with the associated collection decorator.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class BaseCollectionDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: Draper::CollectionDecorator overrides
  # ===========================================================================

  public

  # @private
  # @type [Symbol, String]
  DEFAULT_ACTION = :index

  # Create a new collection decorator, by default based on the paginator passed
  # in through the *opt* parameter.
  #
  # @param [ActiveRecord::Relation, Paginator, Array, nil] obj
  # @param [Hash]                                          opt
  #
  def initialize(obj = nil, **opt)
    with = opt.delete(:with) || self.class.decorator_class
    ctx  = initialize_context(action: DEFAULT_ACTION, **opt)
    obj  = ctx[:paginator] if obj.nil?
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
  DEBUG_DECORATOR_COLLECTION = true?(ENV_VAR['DEBUG_DECORATOR_COLLECTION'])

  # Define the association between a collection decorator and the decorator for
  # its elements.
  #
  # This also causes the element decorator's SharedDefinitions module to be
  # included so that the collection decorator acquires the same definitions.
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
    @ctrlr_type      = @decorator_class.ctrlr_type
    definitions      = "#{base}::SharedDefinitions".safe_constantize
    include(definitions) if definitions.is_a?(Module)
    debug_inheritance    if DEBUG_DECORATOR_COLLECTION
  end

end

__loading_end(__FILE__)
