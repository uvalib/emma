# app/decorators/base_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common base for decorator classes.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Model]
#
class BaseDecorator < Draper::Decorator

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Controls
  include BaseDecorator::Download
  include BaseDecorator::Fields
  include BaseDecorator::Form
  include BaseDecorator::Grid
  include BaseDecorator::Helpers
  include BaseDecorator::Hierarchy
  include BaseDecorator::Links
  include BaseDecorator::List
  include BaseDecorator::Lookup
  include BaseDecorator::Menu
  include BaseDecorator::Pagination
  include BaseDecorator::Row
  include BaseDecorator::Submission
  include BaseDecorator::Table

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generic path helper methods.
  #
  module SharedPathMethods

    include BaseDecorator::Helpers

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def index_path(item = nil, **opt)
      opt.except!(:action)
      path_for(item, **opt)
    end

    def show_select_path(*, **opt)
      path_for(**opt, action: :show_select)
    end

    def show_path(item = nil, **opt)
      path_for(item, **opt, action: :show)
    end

    def new_path(item = nil, **opt)
      path_for(item, **opt, action: :new)
    end

    def create_path(item = nil, **opt)
      path_for(item, **opt, action: :create)
    end

    def edit_select_path(*, **opt)
      path_for(**opt, action: :edit_select)
    end

    def edit_path(item = nil, **opt)
      path_for(item, **opt, action: :edit)
    end

    def update_path(item = nil, **opt)
      path_for(item, **opt, action: :update)
    end

    def delete_select_path(*, **opt)
      path_for(**opt, action: :delete_select)
    end

    def delete_path(item = nil, **opt)
      path_for(item, **opt, action: :delete)
    end

    def destroy_path(item = nil, **opt)
      path_for(item, **opt, action: :destroy)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # id_for
    #
    # @param [String,Model,Hash,Array,nil] item
    # @param [Hash]                        opt
    #
    # @return [String, Model, Hash, nil]
    #
    def id_for(item = nil, **opt)
      id   = opt[:id]
      id ||= (item if item.is_a?(Array))
      id ||= object_class.try_key(item, :id)
      id ||= try(:object).try(:id)
      # noinspection RubyMismatchedReturnType
      id.is_a?(Array) ? id.join(',') : id
    end

    # path_for
    #
    # @param [Model,Hash,Array,nil] item
    # @param [Hash]                 opt
    #
    # @return [String]
    #
    def path_for(item = nil, **opt)
      opt.compact!
      opt[:controller] = opt.delete(:ctrlr) || opt[:controller] || ctrlr_type
      opt[:only_path]  = true unless opt.key?(:only_path)
      opt[:id]         = opt.delete(:selected) if opt.key?(:selected)
      unless opt[:id] || opt.except(:controller, :action, :only_path).present?
        opt[:id] = id_for(item) unless menu_action?(opt[:action])
      end
      h.url_for(opt)
    end

  end

  # Methods available to every decorator class and decorator class instance.
  #
  module SharedGenericMethods

    include BaseDecorator::Common
    include BaseDecorator::Configuration
    include BaseDecorator::Controls
    include BaseDecorator::Download
    include BaseDecorator::Fields
    include BaseDecorator::Form
    include BaseDecorator::Grid
    include BaseDecorator::Helpers
    include BaseDecorator::Hierarchy
    include BaseDecorator::Links
    include BaseDecorator::List
    include BaseDecorator::Lookup
    include BaseDecorator::Menu
    include BaseDecorator::Pagination
    include BaseDecorator::Row
    include BaseDecorator::Submission
    include BaseDecorator::Table

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Emma::Config
      extend  Emma::Config
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The default CSS class for a collection of the decorated item.
    #
    # @return [String]
    #
    def list_css_class
      "#{model_type}-list"
    end

    # Indicate whether the current user has the capability of performing the
    # given operation.
    #
    # @param [Symbol, String, nil] action
    # @param [any, nil]            subject      Default: `#object_class`.
    # @param [any, nil]            extra_args
    #
    # @see Ability#can?
    #
    def can?(action, subject = nil, *extra_args)
      subject ||= ar_class || object_class
      h.can?(action, subject, *extra_args)
    end

    # config_button_values
    #
    # @param [String, Symbol] action
    #
    # @return [Hash{Symbol=>Hash{Symbol=>String,Hash}}]
    #
    def config_button_values(action)
      config = action_config(action) || {}
      config.select { |k, v| v.is_a?(Hash) unless k.start_with?('_') }
    end

    # link_to_action
    #
    # @param [String, nil] label
    # @param [Hash]        opt        Passed to LinkHelper#link_to_action.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def link_to_action(label, **opt)
      opt[:ctrlr] = opt.delete(:controller) || opt[:ctrlr] || ctrlr_type
      h.link_to_action(label, **opt) || ERB::Util.h(label || '')
    end

  end

  # Methods for every decorator class instance.
  #
  #--
  # noinspection RubyTooManyMethodsInspection
  #++
  module SharedInstanceMethods

    include SharedPathMethods
    include SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::Helpers overrides
    # =========================================================================

    public

    # current_user
    #
    # @return [User, nil]
    #
    def current_user
      user = context[:user]
      user || super unless user == :none
    end

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # The model associated with the decorator instance.
    #
    # @return [Symbol]
    #
    def model_type
      self.class.model_type
    end

    # The controller associated with the decorator.
    #
    # @return [Symbol]
    #
    def ctrlr_type
      self.class.ctrlr_type
    end

    # The ActiveRecord subclass associated with the decorator instance.
    #
    # @return [Class, nil]
    #
    def ar_class
      self.class.ar_class
    end

    # null_object
    #
    # @return [Object]
    #
    def null_object
      self.class.null_object
    end

    # config_lookup
    #
    # @param [String, Array] path     Partial I18n path.
    # @param [Hash]          opt      To ConfigurationHelper#config_lookup
    #
    # @return [any, nil]
    #
    def config_lookup(*path, **opt)
      opt[:action] ||= context[:action]
      super
    end

    # =========================================================================
    # :section: Object overrides
    # =========================================================================

    public

    def nil?
      object.nil? || (object == null_object)
    end

    def blank?
      object.blank? || (object == null_object)
    end

    def present?
      !blank?
    end

    # This makes the assumption that duplicating the decorator is intended to
    # produce a new "wrapper" around the associated object and not to also
    # create a new object as well (which can lead to unexpected results).
    #
    def dup
      # noinspection RubyMismatchedReturnType
      self.class.new(object.presence)
    end

    # This makes the assumption that duplicating the decorator is intended to
    # produce a new "wrapper" around the associated object and not to also
    # create a new object as well (which can lead to unexpected results).
    #
    def deep_dup
      # noinspection RubyMismatchedReturnType
      dup
    end

    # Modify the inspection to limit the size of individual element results.
    #
    # @param [Integer] max            Maximum characters per element.
    #
    # @return [String]
    #
    def inspect(max: 256)
      vars =
        instance_variables.map do |var|
          "#{var}=%s" % instance_variable_get(var).inspect.truncate(max)
        end
      "#<#{self.class.name}:#{object_id} %s>" % vars.join(' ')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create a value for #context based on the parameters supplied through the
    # initializer.
    #
    # @param [Hash] opt
    #
    # @return [Hash]                  Suitable for assignment to #context.
    #
    def initialize_context(**opt)
      ctx = opt.delete(:context)&.merge(opt) || opt
      ctx[:controller] &&= ctx[:controller].to_sym
      ctx[:action]     &&= ctx[:action].to_sym
      ctx
    end

    # Get the first entry from Draper::Decorator#context matching any of the
    # given key(s).
    #
    # @param [Array<Symbol>] keys
    #
    # @return [any, nil]
    #
    def context_value(*keys)
      keys = keys.flatten.map!(&:to_s)
      keys = keys.flat_map { |k| [k.pluralize, k.singularize] }.map!(&:to_sym)
      context.values_at(*keys).compact.first
    end

    # options
    #
    # @return [Options]
    #
    def options
      context[:options] || raise("no Options class for #{model_type}")
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # request_values
    #
    # @param [Array<Symbol>] keys
    #
    # @return [Hash]
    #
    def request_values(*keys)
      keys = keys.flatten.presence || %i[referrer url fullpath]
      case (req = context[:request] || request)
        when Rack::Request::Helpers then keys.map { |k| [k, req.try(k)] }.to_h
        when Hash                   then req
        else                             {}
      end
    end

    # request_value
    #
    # @param [Symbol] key
    #
    # @return [any, nil]
    #
    def request_value(key)
      request_values(key)[key]
    end

    # param_values
    #
    # @return [Hash{Symbol=>any}]
    #
    def param_values
      normalize_hash(context[:params] || request_value(:params))
    end

    # session_values
    #
    # @return [Hash{String=>any}]
    #
    def session_values
      values = context[:session] || request_value(:session)
      values.to_hash
    end

    # referrer
    #
    # @param [Hash, nil] opt
    #
    # @return [any, nil]
    #
    def referrer(opt = nil)
      opt&.dig(:referrer) || request_value(:referrer)
    end

    # local_request?
    #
    # @param [Hash, nil] opt
    #
    def local_request?(opt = nil)
      referrer(opt).to_s.start_with?(root_url)
    end

    # same_request?
    #
    # @param [Hash, nil] opt
    #
    def same_request?(opt = nil)
      opt ||= request_values(:referrer, :url, :fullpath)
      (ref = opt[:referrer]).present? &&
        opt.values_at(:url, :fullpath).any? { |u| u&.sub(/\?.*$/, '') == ref }
    end

    # Return the best :href value to use to the previous page.
    #
    # If the HTTP *Referer* is not the same as the current path, that is used
    #
    # @param [Hash, nil]   opt
    # @param [String, nil] fallback
    #
    # @return [String]
    # @return [nil]                   Only when *fallback* is *nil*.
    #
    def back_path(opt = nil, fallback: 'javascript:history.back();')
      opt ||= request_values(:referrer, :url, :fullpath)
      ref = referrer(opt).presence
      # noinspection RubyMismatchedArgumentType
      if ref && same_request?(opt)
        uri = URI(ref)
        uri.path = '/' + uri.path.delete_prefix('/').split('/').shift
        uri.to_s
      elsif ref && local_request?(opt) && !ref.include?('sign_in')
        ref
      else
        fallback
      end
    end

    # root_url
    #
    # @return [String]
    #
    def root_url(...)
      request_value(:base_url) || ''
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The value of Draper::Decorator#object_class accessible from within the
    # decorator instance.
    #
    # @return [Class]
    #
    def object_class
      self.class.object_class
    end

    # Draper::Decorator#decorate accessible from within the decorator instance.
    #
    # @param [Model] item
    # @param [Hash]  opt              Passed to the decorator initializer.
    #
    # @return [BaseDecorator]
    #
    def decorate(item, **opt)
      opt[:context] = context.except(:action) unless opt.key?(:context)
      self.class.decorate(item, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # help_topic
    #
    # @param [Symbol, nil] sub_topic  Def: :sub_topic or :action from `context`
    # @param [Symbol, nil] topic      Default: `model_type`.
    #
    # @return [Array<Symbol>]
    #
    def help_topic(sub_topic = nil, topic = nil)
      topic     ||= model_type
      sub_topic ||= context[:sub_topic] || context[:action]
      sub_topic   = nil if sub_topic == :index
      sub_topic ? [topic, sub_topic] : [topic]
    end

    # Title string for use with the '<head><title>' element.
    #
    # @param [String, nil]     value    Value to use if given.
    # @param [Boolean, String] default  Passed to #page_value.
    # @param [Hash]            opt      Passed to #page_value.
    #
    # @return [String]
    #
    def page_meta_title(value = nil, default: true, **opt)
      @page_meta_title   = nil                       if opt.present?
      @page_meta_title   = page_value(value,  **opt) if value
      @page_meta_title ||= page_value(:label, **opt, default: default)
    end

    # Title string for use with the main heading on the displayed page.
    #
    # @param [String, nil]     value    Value to use if given.
    # @param [Boolean, String] default  Passed to #page_value.
    # @param [Hash]            opt      Passed to #page_value.
    #
    # @return [String]
    #
    def page_title(value = nil, default: true, **opt)
      @page_title   = nil                       if opt.present?
      @page_title   = page_value(value,  **opt) if value
      @page_title ||= page_value(:title, **opt, default: default)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Configuration value for this controller/action.
    #
    # @param [Symbol, String, nil] value    Value or configuration item.
    # @param [Boolean, String]     default  Fallback if config item missing.
    # @param [Hash]                opt      Optional interpolation values.
    #
    # @return [String, nil]
    #
    def page_value(value, default: true, **opt)
      action = opt.delete(:action) || context[:action]
      # noinspection RubyMismatchedArgumentType
      value  = action_config(action)&.dig(value) if value.is_a?(Symbol)
      if value
        interpolate(value, object, **opt)
      elsif default.is_a?(TrueClass)
        [action, model_type].map { |v| v.to_s.titleize }.join(' ')
      elsif default
        default.to_s
      end
    end

  end

  # Methods for every decorator class.
  #
  # @!attribute [r] object_class
  #   Draper::Decorator#object_class
  #   @return [Class]
  #
  module SharedClassMethods

    include SharedPathMethods
    include SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # The model associated with instances of this decorator.
    #
    # @return [Symbol]
    #
    # @see #decorator_for
    #
    def model_type
      @model_type
    end

    # The controller associated with the decorator.
    #
    # @return [Symbol]
    #
    # @see BaseDecorator#decorator_for
    #
    def ctrlr_type
      @ctrlr_type
    end

    # The ActiveRecord subclass associated with instances of this decorator.
    #
    # @return [Class, nil]
    #
    def ar_class
      @ar_class
    end

    # null_object
    #
    # @return [Object]
    #
    def null_object
      # noinspection RubyMismatchedArgumentType
      object_class.new(nil)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Override Draper::Decorator#decorate to ensure that the right decorator
    # instance is generated for *item*.
    #
    # @param [Model, nil] item
    # @param [Hash]       opt         Passed to the decorator initializer.
    #
    # @return [BaseDecorator]
    #
    def decorate(item, **opt)
      # noinspection RubyMismatchedArgumentType
      generate(item, force: true, **opt)
    end

    # Generate a decorator instance.
    #
    # @param [Class, Object, nil] item
    # @param [Boolean]            force
    # @param [Hash]               opt   Passed to the decorator initializer.
    #
    # @raise [RuntimeError]           If no decorator could be determined.
    #
    # @return [BaseDecorator]
    #
    def generate(item, force: false, **opt)
      sub = ObjectClassMap.get(item) || OtherClassMap.get(item)
      raise "No decorator for #{item.class}" unless sub || force || item.nil?
      opt[:from_internal] = true
      # noinspection RubyMismatchedArgumentType, RubyArgCount
      # noinspection RubyMismatchedReturnType
      sub&.new(item, **opt) || new(item, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Show how a decorator handles the methods of the object that it wraps.
    #
    # @return [void]
    #
    def debug_inheritance
      obj = (new rescue nil) or raise('could not create instance')
      ary = obj.is_a?(Array)
      cls = ary ? Array   : object_class
      typ = ary ? 'ARRAY' : 'MODEL'
      ldr = "#{typ} METHOD for #{self} #{cls}"
      cls.instance_methods(true).sort.each do |m|
        loc = obj.instance_eval { method(m).source_location rescue [] }
        #next if loc.blank?
        #next unless loc&.first&.include?('/decor')
        __output "#{ldr}.#{m} ->\t#{loc&.join(':')}"
      end
    rescue => error
      # noinspection RubyScope
      __output "#{typ} METHOD SKIPPING #{self} - #{error}"
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      if base.is_a?(Module) && (base.to_s.demodulize == 'SharedClassMethods')
        # noinspection RbsMissingTypeSignature
        base.module_eval do

          # Override BaseDecorator::SharedClassMethods#null_object in order to
          # established a specific object as "the" null object (for use with
          # the "==" operator).
          #
          # @return [Object]
          #
          def null_object
            @null_object ||= super
          end

        end
      end
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

class BaseDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: Draper::Decorator overrides
  # ===========================================================================

  public

  # @private
  # @type [Symbol, String]
  DEFAULT_ACTION = :show

  # initialize
  #
  # @param [any, nil] obj
  # @param [Hash]     opt
  #
  def initialize(obj = nil, **opt)
    unless opt.delete(:from_internal)
      raise "Unexpected: #{self.class}.new(#{obj.class})"
    end
    ctx = initialize_context(action: DEFAULT_ACTION, **opt)
    obj = null_object if obj.nil?
    # noinspection RubyMismatchedArgumentType
    super(obj, context: ctx)
  end

  # ===========================================================================
  # :section: Draper::Decorator overrides
  # ===========================================================================

  public

  # In this scheme #decorator_for is required for any subclass that is not
  # abstract.
  #
  # @param [Class] object_class
  #
  # @return [void]
  #
  # @deprecated Use "decorator_for" instead of "decorates"
  #
  def self.decorates(object_class)
    __output 'WARNING: Use "decorator_for" instead of "decorates"'
    decorator_for(object_class)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Set to *true* to see how each decorator handles the methods of the object
  # type that it decorates.
  #
  # @type [Boolean]
  #
  # @see BaseCollectionDecorator#DEBUG_COLLECTION_INHERITANCE
  #
  DEBUG_DECORATOR_INHERITANCE = false

  # Takes the place of Draper::Decorator#decorates and is required for any
  # decorator subclass that is not abstract.
  #
  # @param [Array<Class, Symbol, Hash>] args
  #
  # @return [void]
  #
  def self.decorator_for(*args)
    other = []
    if args.first.is_a?(Hash)
      opt   = args.first.dup
      other = opt.extract!(:and).values.flatten.compact
      mod, obj = opt.first
    elsif args.size == 1
      obj = mod = args.first
    elsif args.first.is_a?(Class)
      obj, mod = args
    else
      mod, obj = args
    end

    # noinspection RubyMismatchedArgumentType
    set_model_type(mod)
    set_object_class(obj, *other)&.include(Draper::Decoratable)

    # Override BaseDecorator#new so that instances of this terminal subclass
    # can be created.
    def self.new(obj = nil, **opt)
      opt[:from_internal] = true
      super
    end

    debug_inheritance if DEBUG_DECORATOR_INHERITANCE
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Set @model_type and @ctrlr_type based on *mt*.
  #
  # @param [Class, Symbol, String, nil] mt
  #
  # @return [Symbol, nil]
  #
  #--
  # noinspection RailsParamDefResolve, RubyMismatchedVariableType
  #++
  def self.set_model_type(mt)
    raise 'Nil model_type' unless mt
    ct = mt.try(:ctrlr_type) || mt.try(:controller)&.name || mt.try(:name)
    ct = ct.underscore.to_sym            if ct.is_a?(String)
    mt = mt.model_type                   if mt.respond_to?(:model_type)
    mt = mt.model_name.singular          if mt.respond_to?(:model_name)
    mt = mt.demodulize.underscore.to_sym if mt.is_a?(String)
    @model_type = mt
    @ctrlr_type = ct || @model_type
    ModelTypeMap.set(@model_type, self)
  end

  # Set @object_class and @ar_class based on *obj*.
  #
  # @param [Class, Symbol, String, nil]        obj
  # @param [Array<Class, Symbol, String, nil>] other
  #
  # @return [Class, nil]
  #
  #--
  # noinspection RubyResolve, RubyMismatchedVariableType
  #++
  def self.set_object_class(obj, *other)
    meth          = "BaseDecorator.#{__method__}"
    @object_class = obj = to_class(obj, meth) or raise 'FATAL'
    @other_class  = other.map! { |c| to_class(c, meth) }.compact_blank!
    @ar_class     = arc = [obj, *other].find { |c| c < ApplicationRecord }
    @ar_class   &&=
      (ARClassMap.set(arc,  self) or map_warn(ARClassMap, arc, meth))
    @other_class.each do |oc|
      OtherClassMap.set(oc, self) or map_warn(OtherClassMap, oc, meth)
    end
    ObjectClassMap.set(obj, self) or map_warn(ObjectClassMap, obj, meth)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  private

  # to_class
  #
  # @param [any, nil]       c
  # @param [String, Symbol] meth
  #
  # @return [Class, nil]
  #
  def self.to_class(c, meth)
    c = c.to_s             if c.is_a?(Symbol)
    c = c.safe_constantize if c.is_a?(String)
    return c               if c.is_a?(Class)
    Log.warn("#{meth}: not a Class: #{c.inspect}")
  end

  # @private
  def self.map_warn(map, key, meth)
    return if key == User # NOTE: will already be set to AccountDecorator.
    Log.warn("#{meth}: #{map}[#{key}]: already set to #{map.get(key)}")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Methods for mapping unique key values to decorator classes.
  #
  module Mapper

    delegate to: :table

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # A table of keys and their associated decorator classes.
    #
    # @return [Hash{any=>Class}]
    #
    def table
      @table ||= {}
    end

    # Get the matching decorator class.
    #
    # @param [any, nil] key
    #
    # @return [Class, nil]            The associated decorator class.
    #
    def get(key)
      key = normalize(key) or return
      table[key]
    end

    # Set the matching decorator class.
    #
    # @param [any, nil] key
    # @param [Class]    dec           Decorator class
    # @param [Boolean]  force         Update the #table entry unconditionally.
    #
    # @return [any, nil]              The normalize key if added to the table.
    #
    def set(key, dec, force: false)
      key = normalize(key) or return
      if force || !table[key]
        table[key] = dec
        key
      end
    end

    alias :[] :get

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Normalize the provided value as a valid key or *nil*.
    #
    # @param [any, nil] key
    #
    # @return [any, nil]
    #
    def normalize(key)
      key.presence
    end

  end

  # Methods for mapping model types to decorator classes.
  #
  module TypeMapper

    include Mapper

    def normalize(mod)
      mod = mod.first if mod.is_a?(Array)
      # noinspection RubyMismatchedArgumentType
      mod.is_a?(Symbol) ? mod : Model.for(mod) if mod
    end

  end

  # Methods for mapping classes to decorator classes.
  #
  module ClassMapper

    include Mapper

    def normalize(obj)
      obj = obj.first         if obj.is_a?(Array)
      obj = obj&.object_class if obj&.respond_to?(:object_class)
      obj = obj&.class        if obj && !obj.is_a?(Class)
      obj
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A singleton table of model types and their associated decorator classes.
  #
  class ModelTypeMap
    class << self
      include TypeMapper
    end
  end

  # A singleton table of object classes and their associated decorator classes.
  #
  class ObjectClassMap
    class << self
      include ClassMapper
    end
  end

  # A singleton table of ActiveRecord classes and their associated decorators.
  #
  class ARClassMap
    class << self
      include ClassMapper
    end
  end

  # A singleton table of secondary mappings to decorator classes.
  #
  class OtherClassMap
    class << self
      include ClassMapper
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # The pattern used within #js_properties Path values to indicate that the
  # ID of the item should be interpolated at that point.
  #
  # @type [String]
  #
  # @see file:app/assets/javascripts/shared/strings.js *interpolate()*
  #
  JS_ID = '${id}'

  # Client-side scripting which are supplied via 'assets:precompile'.
  #
  # @return [Hash]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb
  #
  def self.js_properties

    record_properties = fetch_properties(
      List: {
        class:    list_css_class,
      },
      FilterOptions: {
        class:    :FILTER_OPTIONS_CLASS,
        Control:  { class: :FILTER_CONTROL_CLASS },
      },
      GroupPanel: {
        class:    :GROUP_PANEL_CLASS,
        Control:  { class: :GROUP_CONTROL_CLASS },
      },
      ListFilter: {
        class:    :LIST_FILTER_CLASS,
        Control:  { class: :FILTER_CONTROL_CLASS },
      },
      StateGroup: fetch_property(:STATE_GROUP)&.keys,
    )

    path_properties = {
      index:      (index_path               rescue nil),
      show:       (show_path(id: JS_ID)     rescue nil),
      new:        (new_path                 rescue nil),
      create:     (create_path              rescue nil),
      edit:       (edit_path(id: JS_ID)     rescue nil),
      update:     (update_path(id: JS_ID)   rescue nil),
      delete:     (delete_path(id: JS_ID)   rescue nil),
      destroy:    (destroy_path(id: JS_ID)  rescue nil),
    }.compact

    {
      Action:     form_actions,
      Filter:     field_groups,
      Status:     status_markers,
      Uploader:   fetch_property(:UPLOADER),
      Record:     record_properties,
      Mime:       { to_fmt: FileNaming.mime_to_fmt },
      Path:       path_properties,
    }
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # fetch_property
  #
  # @param [any, nil] item
  #
  # @return [any, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def self.fetch_property(item)
    return fetch_properties(item) if item.is_a?(Hash)
    item = safe_const_get(item)   if item.is_a?(Symbol)
    item = item.call rescue nil   if item.is_a?(Proc)
    item = item.compact           if item.is_a?(Enumerable)
    item.presence
  end

  # Invoke #fetch_property on each Hash value.
  #
  # @param [Hash] hash
  #
  # @return [Hash]
  #
  def self.fetch_properties(hash)
    hash.transform_values { |v| fetch_property(v) }.compact
  end

end

__loading_end(__FILE__)
