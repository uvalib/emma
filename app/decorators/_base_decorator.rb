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

  include_submodules(self)

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include BaseDecorator::Fields
    include BaseDecorator::Form
    include BaseDecorator::Hierarchy
    include BaseDecorator::Links
    include BaseDecorator::List
    include BaseDecorator::Menu
    include BaseDecorator::Pagination
    include BaseDecorator::Table
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Definitions to support inclusion of helpers.
  #
  # == Implementation Notes
  # This approach avoids `include Draper::LazyHelpers` because this can make it
  # difficult to pin down where problems with the use of Draper::ViewContext
  # originate when including /app/helpers/**.
  #
  module Helpers

    include Draper::ViewHelpers

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Explicit overrides for the sake of those helpers which still rely on
    # direct access to controller-related items.
    #
    # @!method request
    # @!method params
    # @!method session
    # @!method current_user
    # @!method current_ability
    #
    %i[request params session current_user current_ability].each do |meth|
      define_method(meth) do
        controller_context.send(meth)
      end
    end

    # Explicit overrides for the sake of those helpers which still rely on
    # direct access to controller-related items.
    #
    # @!method cookies
    #
    %i[cookies].each do |meth|
      define_method(meth) do
        request.cookies
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Direct access to the controller.
    #
    # @return [ApplicationController]
    #
    # == Implementation Notes
    # This probably isn't "cricket", but app/helpers/**.rb generally expect
    # access to controller values, and while the decorator subclasses are
    # relying on including these helpers, there is a need to access these
    # values directly.
    #
    # While you *can* access these from Draper::ViewContext#current (via
    # Draper::ViewHelpers#helpers [i.e., prefixing with "h."] or via
    # Draper::LazyHelpers#method_missing), the values don't seem to be coming
    # back correctly.
    #
    def controller_context
      Draper::ViewContext.controller
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Helper methods explicitly generated for the sake of avoiding LazyHelpers.
    #
    # @!method asset_path(*args)
    #   @see ActionView::Helpers::AssetUrlHelper#asset_path
    #
    # @!method safe_join(*args)
    #   @see ActionView::Helpers::OutputSafetyHelper#safe_join
    #
    %i[
      asset_path
      safe_join
    ].each do |meth|
      define_method(meth) do |*args|
        helpers.send(meth, *args)
      end
      ruby2_keywords(meth)
    end

    # Helper methods explicitly generated for the sake of avoiding LazyHelpers.
    #
    7    # @!method button_tag(*args, &block)
    #   @see ActionView::Helpers::FormTagHelper#button_tag
    #
    # @!method content_tag(*args, &block)
    #   @see ActionView::Helpers::TagHelper#content_tag
    #
    # @!method form_tag(*args, &block)
    #   @see ActionView::Helpers::FormTagHelper#form_tag
    #
    # @!method image_tag(*args, &block)
    #   @see ActionView::Helpers::AssetTagHelper#image_tag
    #
    # @!method link_to(*args, &block)
    #   @see ActionView::Helpers::UrlHelper#link_to
    #
    # @!method submit_tag(*args, &block)
    #   @see ActionView::Helpers::FormTagHelper#submit_tag
    #
    %i[
      button_tag
      content_tag
      form_tag
      image_tag
      link_to
      submit_tag
    ].each do |meth|
      define_method(meth) do |*args, &block|
        helpers.send(meth, *args, &block)
      end
      ruby2_keywords(meth)
    end

    # Defined here for the sake of RepositoryHelper.
    #
    def retrieval_path(*args)
      h.retrieval_path(*args)
    end

    include ConfigurationHelper
    include FormHelper
    include HtmlHelper
    include ImageHelper
    include LinkHelper
    include PanelHelper
    include PopupHelper
    include RepositoryHelper
    include RoleHelper
    include ScrollHelper
    include SearchModesHelper
    include SessionDebugHelper
    include TreeHelper

  end

  # Generic path helper methods.
  #
  module Paths

    include Helpers

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def index_path(*, **opt)
      opt.except!(:action)
      path_for(**opt)
    end

    def show_path(item = nil, **opt)
      opt[:action] = :show
      opt[:id]     = id_for(item, **opt)
      path_for(**opt)
    end

    def new_path(*, **opt)
      opt[:action] = :new
      path_for(**opt)
    end

    def create_path(*, **opt)
      opt[:action] = :create
      path_for(**opt)
    end

    def edit_select_path(**opt)
      opt[:id] ||= 'SELECT'
      edit_path(**opt)
    end

    def edit_path(item = nil, **opt)
      opt[:action] = :edit
      opt[:id]     = id_for(item, **opt)
      path_for(**opt)
    end

    def update_path(item = nil, **opt)
      opt[:action] = :update
      opt[:id]     = id_for(item, **opt)
      path_for(**opt)
    end

    def delete_select_path(**opt)
      opt[:id] ||= 'SELECT'
      delete_path(**opt)
    end

    def delete_path(item = nil, **opt)
      opt[:action] = :delete
      opt[:id]     = id_for(item, **opt)
      path_for(**opt)
    end

    def destroy_path(item = nil, **opt)
      opt[:action] = :destroy
      opt[:id]     = id_for(item, **opt)
      path_for(**opt)
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
      # noinspection RailsParamDefResolve
      id = opt[:id] || (item ||= try(:object))&.try(:id) || item
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
      opt[:only_path] = true unless opt.key?(:only_path)
      # noinspection RailsParamDefResolve
      item ||=
        (try(:object) if opt.except(:controller, :action, :only_path).blank?)
      opt[:id]         ||= item&.id if item&.id
      opt[:controller] ||= model_type
      h.url_for(opt)
    end

  end

  # Model/controller related configuration information relative to model_type.
  #
  module Configuration

    include Helpers

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # model_type
    #
    # @return [Symbol]
    #
    def model_type
      not_implemented 'To be overridden'
    end

    # ar_class
    #
    # @return [Class, nil]
    #
    def ar_class
      not_implemented 'To be overridden'
    end

    # null_object
    #
    # @return [Object]
    #
    def null_object
      not_implemented 'To be overridden'
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The start of a configuration YAML path (including the leading "emma.")
    #
    # @return [Symbol]
    #
    def model_config_base
      model_type
    end

    # The start of a configuration YAML path (including the leading "emma.")
    #
    # @return [Symbol]
    #
    def controller_config_base
      model_type
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get the controller/action configuration for the model.
    #
    # @param [Symbol, nil] type
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def controller_config(type = nil)
      type ||= controller_config_base
      ApplicationHelper::CONTROLLER_CONFIGURATION[type] || {}.freeze
    end

    # Get configured record fields for the model.
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def model_config(**)
      Model.config_for(model_config_base)
    end

    # Get configured record fields relevant to an :index action for the model.
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def model_index_fields(**)
      Model.index_fields(controller_config_base)
    end

    # Get configured record fields relevant to an :show action for the model.
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def model_show_fields(**)
      Model.show_fields(controller_config_base)
    end

    # Get all configured record fields for the model.
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def model_database_fields(**)
      Model.database_fields(model_config_base)
    end

    # Get all configured record fields for the model.
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def model_form_fields(**)
      Model.form_fields(model_config_base)
    end

    # Configuration properties for a field.
    #
    # @param [Symbol]    field
    # @param [*]         value
    # @param [Hash, nil] config
    #
    # @return [Field::Type, nil]
    #
    # @see Field#for
    #
    def field_for(field, value: nil, config: nil)
      Field.for(object, field, model_config_base, value: value, config: config)
    end

    # Configuration properties for a field.
    #
    # @param [Symbol, String, nil] field
    # @param [Symbol, String, nil] action
    #
    # @return [Hash]                  Frozen result.
    #
    def field_configuration(field, action = nil, **)
      Field.configuration_for(field, model_config_base, action)
    end

    # Find the field whose configuration entry has a matching label.
    #
    # @param [String, Symbol, nil] label
    # @param [Symbol, String, nil] action
    #
    # @return [Hash]                  Frozen result.
    #
    def field_configuration_for_label(label, action = nil, **)
      Field.configuration_for_label(label, model_config_base, action)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # show_tooltip
    #
    # @return [String, nil]
    #
    def show_tooltip
      controller_config.dig(:show, :tooltip)
    end

    # config_lookup
    #
    # @param [String, Array] path     Partial I18n path.
    # @param [Hash]          opt      To ConfigurationHelper#config_lookup
    #
    # @return [Any]
    #
    def config_lookup(*path, **opt)
      opt[:ctrlr]  ||= opt.delete(:controller) || controller_config_base
      opt[:action] ||= :index
      h.config_lookup(*path, **opt)
    end

  end

  # Methods available to every decorator class and decorator class instance.
  #
  module Methods

    include Configuration

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include BaseDecorator::Fields
      include BaseDecorator::Form
      include BaseDecorator::Hierarchy
      include BaseDecorator::Links
      include BaseDecorator::List
      include BaseDecorator::Menu
      include BaseDecorator::Pagination
      include BaseDecorator::Table
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
    def css_list_class
      "#{model_type}-list"
    end

    # Indicate whether the current user has the capability of performing the
    # given operation.
    #
    # @param [Symbol]   action
    # @param [Any, nil] target        Default: `#object_class`.
    #
    # @see CanCan::ControllerAdditions#can?
    #
    def can?(action, target = nil)
      target ||= ar_class || object_class
      h.can?(action, target)
    end

    # config_button_values
    #
    # @param [String, Symbol] action
    #
    # @return [Hash{Symbol=>Hash{Symbol=>String,Hash}}]
    #
    def config_button_values(action)
      action_config = controller_config[action] || {}
      action_config.select { |_, v| v.is_a?(Hash) }
    end

    # form_action_link
    #
    # @param [String, nil] label
    # @param [Hash]        opt        Passed to LinkHelper#link_to_action.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def link_to_action(label, **opt)
      opt[:controller] ||= model_type
      h.link_to_action(label, **opt) || ERB::Util.h(label || '')
    end

  end

  # Methods for every decorator class instance.
  #
  # @!attribute [r] object
  #   Set in Draper#initialize
  #   @return [Model]
  #
  # @!attribute [r] context
  #   Set in Draper#initialize
  #   @return [Hash{Symbol=>*}]
  #
  module InstanceMethods

    include Paths
    include Methods

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

    # model_type
    #
    # @return [Symbol]
    #
    def model_type
      self.class.model_type
    end

    # ar_class
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
    # @return [Any]
    #
    def config_lookup(*path, **opt)
      opt[:action] ||= context[:action]
      super(*path, **opt)
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

    # noinspection RubyMismatchedReturnType
    def dup
      obj = (object.dup if present?)
      self.class.new(obj)
    end

    # noinspection RubyMismatchedReturnType
    def deep_dup
      obj = (object.deep_dup if present?)
      self.class.new(obj)
    end

    # Modify the inspection to limit the size of individual member results.
    #
    # @param [Integer] max            Maximum characters per member.
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
    # initializer
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
    # @return [Any, nil]
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
      context[:options] || Options.new(model_type)
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
    #--
    # noinspection RubyMismatchedReturnType
    #++
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
      values = context[:params] || request_value(:params)
      values ? h.request_parameters(values) : {}
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
      ref = opt[:referrer]
      # noinspection RubyNilAnalysis
      ref.present? && opt.values_at(:url, :fullpath).include?(ref)
    end

    # back_path
    #
    # @param [Hash, nil] opt
    #
    # @return [String, nil]
    #
    def back_path(opt = nil)
      opt ||= request_values(:referrer, :url, :fullpath)
      referrer(opt) if local_request?(opt) && !same_request?(opt)
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
    # @return [Array<Symbol>]
    #
    def help_topic
      action = context[:action]
      action = nil if action == :index
      action ? [model_type, action] : [model_type]
    end

    # Title string for use with the '<head><title>' element.
    #
    # @param [Hash] opt               Passed to #page_value.
    #
    # @return [String]
    #
    def page_meta_title(**opt)
      page_value(:label, **opt)
    end

    # Title string for use with the main heading on the displayed page.
    #
    # @param [Hash] opt               Passed to #page_value.
    #
    # @return [String]
    #
    def page_heading(**opt)
      opt[:default] = true unless opt.key?(:default)
      page_value(:title, **opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Configuration value for this controller/action.
    #
    # @param [Symbol]          item
    # @param [Boolean, String] default
    # @param [Hash]            opt      Optional interpolation values.
    #
    # @return [String]
    #
    def page_value(item, default: true, **opt)
      action = opt.delete(:action) || context[:action]
      value  = controller_config.dig(action, item)
      if value && opt.present?
        value % opt
      elsif value
        value
      elsif default.is_a?(TrueClass)
        [action, model_type].map(&:to_s).map(&:titleize).join(' ')
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
  module ClassMethods

    include Paths
    include Methods

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # model_type
    #
    # @return [Symbol]
    #
    # @see #decorator_for
    #
    def model_type
      @model_type
    end

    # ar_class
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
    # @return [BaseDecorator]
    #
    # @raise [RuntimeError]           If no decorator could be determined.
    #
    def generate(item, force: false, **opt)
      sub = ObjectClassMap.get(item) || OtherClassMap.get(item)
      raise "No decorator for #{item.class}" unless sub || force || item.nil?
      opt.merge!(from_internal: true)
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
        $stderr.puts "#{ldr}.#{m} ->\t#{loc&.join(':')}"
      end
    rescue => err
      # noinspection RubyScope
      $stderr.puts "#{typ} METHOD SKIPPING #{self} - #{err}"
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      if base.is_a?(Module) && (base.to_s.demodulize == 'ClassMethods')
        # noinspection RbsMissingTypeSignature
        base.module_eval do

          # Override BaseDecorator::ClassMethods#null_object in order to
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

  module Common
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  include Common

  # ===========================================================================
  # :section: Draper::Decorator overrides
  # ===========================================================================

  public

  # @private
  DEFAULT_ACTION = :show

  # initialize
  #
  # @param [Any, nil] obj
  # @param [Hash]     opt
  #
  def initialize(obj = nil, **opt)
    unless opt.delete(:from_internal)
      raise "Unexpected: #{self.class}.new(#{obj.class})"
    end
    obj = null_object if obj.nil?
    ctx = initialize_context(**opt).reverse_merge!(action: DEFAULT_ACTION)
    # noinspection RubyMismatchedArgumentType
    super(obj, context: ctx)
  end

  # ===========================================================================
  # :section: Draper::Decorator overrides
  # ===========================================================================

  public

  # In this scheme #decorates is required for any subclass that is not
  # abstract.
  #
  # @param [Class] object_class
  #
  # @return [void]
  #
  def self.decorates(object_class)
    $stderr.puts 'WARNING: Use "decorator_for" instead of "decorates"'
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
      other = extract_hash!(opt, :and).values.flatten
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
      super(obj, **opt.merge!(from_internal: true))
    end

    debug_inheritance if DEBUG_DECORATOR_INHERITANCE
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # set_model_type
  #
  # @param [Class, Symbol, String, nil] mt
  #
  # @return [Symbol, nil]
  #
  def self.set_model_type(mt)
    raise 'Nil model_type' unless mt
    # noinspection RubyMismatchedVariableType, RubyNilAnalysis
    @model_type = mt.is_a?(Symbol) ? mt : mt.to_s.demodulize.underscore.to_sym
    ModelTypeMap.set(@model_type, self)
  end

  # set_object_class
  #
  # @param [Class, Symbol, String, nil]        obj
  # @param [Array<Class, Symbol, String, nil>] other
  #
  # @return [Class, nil]
  #
  #--
  # noinspection RubyResolve
  # noinspection RubyMismatchedReturnType, RubyMismatchedVariableType
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
  # @param [*]              c
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
    # @return [Hash{Any=>Class}]
    #
    def table
      @table ||= {}
    end

    # Get the matching decorator class.
    #
    # @param [Any, nil] key
    #
    # @return [Class, nil]            The associated decorator class.
    #
    def get(key)
      key = normalize(key) or return
      table[key]
    end

    # Set the matching decorator class.
    #
    # @param [Any, nil] key
    # @param [Class]    dec           Decorator class
    # @param [Boolean]  force         Update the #table entry unconditionally.
    #
    # @return [Any, nil]              The normalize key if added to the table.
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
    # @param [Any, nil] key
    #
    # @return [Any, nil]
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
      mod = mod.first      if mod.is_a?(Array)
      mod = Model.for(mod) if mod && !mod.is_a?(Symbol)
      # noinspection RubyMismatchedReturnType
      mod
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
  # @param [Hash{Symbol=>Any}]
  #
  # @see file:app/assets/javascripts/shared/assets.js.erb
  #
  def self.js_properties

    record_properties = fetch_properties(
      List: {
        class: css_list_class,
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
      index:    (index_path               rescue nil),
      show:     (show_path(id: JS_ID)     rescue nil),
      new:      (new_path                 rescue nil),
      create:   (create_path              rescue nil),
      edit:     (edit_path(id: JS_ID)     rescue nil),
      update:   (update_path(id: JS_ID)   rescue nil),
      delete:   (delete_path(id: JS_ID)   rescue nil),
      destroy:  (destroy_path(id: JS_ID)  rescue nil),
    }.compact

    {
      Action: form_actions,
      Filter: field_groups,
      Status: status_markers,
      Upload: fetch_property(:UPLOAD),
      Record: record_properties,
      Mime:   { to_fmt: FileNaming.mime_to_fmt },
      Field:  { empty: EMPTY_VALUE },
      Repo:   { name:  EmmaRepository.pairs, default: EmmaRepository.default },
      Path:   path_properties,
    }
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # fetch_property
  #
  # @param [Any, nil] item
  #
  # @return [Any, nil]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyNilAnalysis
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
    # noinspection RubyMismatchedReturnType
    hash.transform_values { |v| fetch_property(v) }.compact
  end

end

__loading_end(__FILE__)
