# app/models/concerns/model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common model methods.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module Model

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A unique identifier for this model instance.
  #
  # @return [String]
  #
  def identifier
    (respond_to?(:id) ? id : object_id).to_s
  end

  # Indicate whether the Model instance is composed of other Model instances.
  #
  def aggregate?
    self.class.send(__method__)
  end

  # The type for constituent Model elements for a class whose instances are
  # aggregates.
  #
  # @return [Class, nil]
  #
  def aggregate_type
    self.class.send(__method__)
  end

  # The field holding constituent Model elements for a class which supports
  # aggregates.
  #
  # @return [Symbol, nil]
  #
  def aggregate_field
    self.class.send(__method__)
  end

  # Indicate whether the Model instance is primarily a container for a list of
  # other Model instances.
  #
  def collection?
    self.class.send(__method__)
  end

  # The type for constituent Model elements for a class whose instances are
  # collections.
  #
  # @return [Class, nil]
  #
  def collection_type
    self.class.send(__method__)
  end

  # The field holding constituent Model elements for a class whose instances
  # are collections.
  #
  # @return [Symbol, nil]
  #
  def collection_field
    self.class.send(__method__)
  end

  # The constituent Model elements related to this Model instance.
  #
  # @return [Array]   Possibly empty.
  # @return [nil]     If the instance is not an aggregate or collection.
  #
  def elements
    relation_field = [collection_field, aggregate_field].compact.first
    try(relation_field) if relation_field
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  extend ActiveSupport::Concern

  # Methods which extend the including class.
  #
  module ClassMethods

    # Indicate whether instances of the including class are composed of other
    # Model instances.
    #
    def aggregate?
      aggregate_type.present?
    end

    # The type for constituent Model elements for a class whose instances are
    # aggregates.
    #
    # @return [Class<Model>, nil]
    #
    def aggregate_type
      safe_const_get(:BASE_ELEMENT)
    end

    # The field holding constituent Model elements for a class which supports
    # aggregates.
    #
    # @return [Symbol, nil]
    #
    def aggregate_field
      safe_const_get(:BASE_FIELD)
    end

    # Indicate whether the including class is primarily a container for a list
    # of other Model instances.
    #
    def collection?
      collection_type.present?
    end

    # The type for constituent Model elements for a class whose instances are
    # collections.
    #
    # @return [Class<Model>, nil]
    #
    def collection_type
      safe_const_get(:LIST_ELEMENT)
    end

    # The field holding constituent Model elements for a class whose instances
    # are collections.
    #
    # @return [Symbol, nil]
    #
    def collection_field
      safe_const_get(:LIST_FIELD)
    end

    # Create a :LIST_FIELD or :BASE_FIELD constant for a class if it defines
    # :LIST_ELEMENT or :BASE_ELEMENT (respectively).
    #
    # @param [Symbol, String] field_name
    # @param [Class, nil]     field_type
    #
    # @return [Symbol, nil]
    #
    # @see Api::Record::Associations::ClassMethods#has_many
    #
    def set_relation_field(field_name, field_type)
      @check_relations ||= validate_relations
      return unless field_type
      if field_type == collection_type
        const_set(:LIST_FIELD, field_name.to_sym)
      elsif field_type == aggregate_type
        const_set(:BASE_FIELD, field_name.to_sym)
      end
    end

    # Validate the including aggregate/collection class.
    #
    # If a record class is intended to be an aggregate it should both include
    # Api::Shared::AggregateMethods and define :BASE_ELEMENT.
    #
    # If a record class is intended to be a collection it should both include
    # Api::Shared::CollectionMethods and define :LIST_ELEMENT.
    #
    # @raise [SyntaxError]            A problem was detected in development.
    #
    # @return [TrueClass]
    #
    def validate_relations
      a_mod  = ancestors.find { |m| m == Api::Shared::AggregateMethods }
      c_mod  = ancestors.find { |m| m == Api::Shared::CollectionMethods }
      a_type = aggregate_type
      c_type = collection_type
      both   = nil
      miss   = []
      if a_mod && c_mod
        both = [a_mod, c_mod]
      elsif a_type && c_type
        both = [a_type, c_type]
      else
        miss << :BASE_ELEMENT                   if a_mod  && !a_type
        miss << :LIST_ELEMENT                   if c_mod  && !c_type
        miss << Api::Shared::AggregateMethods   if a_type && !a_mod
        miss << Api::Shared::CollectionMethods  if c_type && !c_mod
      end
      failure =
        if both.present?
          both = both.join(' and ') if both.is_a?(Array)
          "found #{both}: cannot be both an aggregate and a collection"
        elsif miss.present?
          miss.map! { |item|
            item = item.to_s
            kind = item.match?(/BASE|Aggregate/) ? :aggregate : :collection
            "#{kind} record missing #{item}"
          }.join('; AND ')
        end
      if failure.present?
        failure = "BAD RECORD DEFINITION for #{self.name}: #{failure}"
        Log.error(failure)
        raise SyntaxError, failure unless production_deployment?
      end
      true
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether *name* is a field defined by this model.
  #
  # @param [Symbol, String, *]
  #
  def include?(name)
    field_names.include?(name&.to_sym)
  end

  # The fields defined by this model.
  #
  # @return [Array<Symbol>]
  #
  def field_names
    @field_names ||=
      if is_a?(ApplicationRecord)
        attribute_names.map(&:to_sym).sort
      else
        instance_variables.map { |v| v.to_s.delete_prefix('@').to_sym }.sort
      end
  end

  # The fields and values for this model instance.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def fields
    if is_a?(ApplicationRecord)
      attributes.symbolize_keys
    else
      field_names.map { |field| [field, send(field)] rescue nil }.compact.to_h
    end
  end

  # The fields and values for this instance as a Hash.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def to_h(**)
    fields
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Frozen Hash returned as a fall-back for failed configuration lookups.
  #
  # @type [Hash]
  #
  EMPTY_CONFIG = {}.freeze

  # Get configured record fields for a model/controller.
  #
  # @param [Symbol, String, Class, Model, Any] type       Model/controller type
  # @param [Boolean]                           no_raise   If *true* return {}
  #
  # @raise [RuntimeError]             If *type* does not map on to a model.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.configuration_fields(type, no_raise: false)
    unless (arg = type).is_a?(Symbol) || (type = model_for(type))
      Log.warn((error = "#{__method__}: #{arg}: invalid"))
      raise error unless no_raise
      return EMPTY_CONFIG
    end
    # noinspection RubyMismatchedArgumentType
    fields_table[type] ||= configured_fields_for(type).deep_freeze
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Keys under "emma.*.record" beginning with an underscore, which represent
  # the control directive for specifying the base configuration.
  #
  # @type [Array<Symbol>]
  #
  BASE_DIRECTIVE = %i[base base_config base_configuration].freeze

  # Keys under "emma.*.record" beginning with an underscore, which define
  # display fields which are filled dynamically.
  #
  # @type [Array<Symbol>]
  #
  SYNTHETIC_FIELDS = %i[synthetic].freeze

  # Keys under "emma.*.record" beginning with an underscore, which do not map
  # on to actual database columns.
  #
  # @type [Array<Symbol>]
  #
  DIRECTIVES = (BASE_DIRECTIVE + SYNTHETIC_FIELDS).freeze

  # Configured record fields for each model/controller.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.fields_table
    # noinspection RbsMissingTypeSignature
    @fields_table ||= {}
  end

  # Combine configuration settings for a given model/controller.
  #
  # @param [Symbol, Any] type
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.configured_fields_for(type)
    return {} unless type.is_a?(Symbol)
    model_config = I18n.t("emma.#{type}", default: nil)&.deep_dup || {}

    # Start with definitions from config/locales/records/*.yml, separating
    # control directives from field name entries.
    directives = {}
    all_fields =
      (model_config[:record] || {}).map { |field, entry|
        name = field.to_s.sub!(/^_/, '')&.to_sym
        if name && DIRECTIVES.include?(name)
          directives[name] = entry
        elsif name
          Log.warn { "#{__method__}(#{type}): #{name}: unexpected directive" }
        end
        [field, Field.normalize(entry, field)] unless name
      }.compact.to_h

    # Special handling so that "emma.search.record" entries are initialized
    # with the equivalent values from the submission record configuration.
    if (base = directives.values_at(*BASE_DIRECTIVE).first).present?
      base = base.values_at(:record, :field) if base.is_a?(Hash)
      base_config, base_field = Array.wrap(base).map(&:to_sym)
      base_config = configuration_fields(base_config)&.dig(:all)
      base_config = base_field.present? && base_config&.dig(base_field) || {}
      all_fields.each_pair do |field, entry|
        all_fields[field] = base_config[field].deep_merge(entry)
      end
    end

    # Add definitions of fields which do not map on to data columns.
    synthetic = directives.values_at(*SYNTHETIC_FIELDS).first || {}
    synthetic.each_pair do |field, entry|
      all_fields[field] = Field.normalize(entry, field).merge!(synthetic: true)
    end

    # Apply adjustments from config/locales/controllers/*.yml then finalize
    # the generic entries.
    (model_config[:display_fields] || {}).each_pair do |field, entry|
      entry = Field.normalize(entry, field)
      all_fields[field] = all_fields[field]&.deep_merge(entry) || entry
    end
    all_fields.transform_values! { |entry| Field.finalize!(entry) }
    all_fields.delete_if { |_, entry| Field.unused?(entry) }

    # Temporary revision of User fields to "disappear" the fields that only
    # apply if Bookshare OAuth2 authentication is in use.
    if %i[account user].include?(type)
      if BS_AUTH
        all_fields.except!(:provider) unless SHIBBOLETH
      else
        all_fields.except!(:access_token, :refresh_token, :effective_id)
      end
    end

    # Identify the fields which map on to database columns.
    database_fields = all_fields.except(*synthetic.keys)

    # For pages that specify their own :display_fields section.  If its
    # value is :all or [:all] then all record fields will be displayed on
    # that page.  Otherwise the section may be an array of field
    # specifications; each may be:
    #
    # * String or Symbol - the field name to show
    # * Hash             - table of field names and label overrides
    #
    controller_configs =
      model_config.map { |action, section|
        next unless section.is_a?(Hash) && section.key?(:display_fields)
        field_list  = Array.wrap(section[:display_fields]).dup
        page_fields = field_list.delete(:all) ? all_fields.deep_dup : {}
        field_list.each do |field_entry|
          field_entry = { field_entry => nil } unless field_entry.is_a?(Hash)
          field_entry.symbolize_keys.each_pair do |field, delta|
            next unless delta || page_fields[field].nil?
            props = page_fields[field] || all_fields[field]&.deep_dup || {}
            props.deep_merge!(Field.normalize(delta, field)) if delta
            Field.finalize!(props, field)
            page_fields[field] = (props unless Field.unused?(props, action))
          end
        end
        page_fields.compact!
        [action, page_fields]
      }.compact.to_h

    # Return with the generic field configurations followed by entries for
    # each model/controller-specific field configuration.
    { all: all_fields, database: database_fields }.merge!(controller_configs)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # @private
  CONFIG_PREFIX = /^\s*(en\.)?emma\./

  # Return the model class associated with *item*.
  #
  # @param [Any, nil] item             Symbol, String, Class, Model
  #
  # @return [Class, nil]
  #
  def self.class_for(item)
    item = item.class             if item.is_a?(Model)
    item = item.base_class        if item.respond_to?(:base_class)
    item = namespace_for(item)    if namespaced?(item)
    item = item.to_s              if item.is_a?(Symbol)
    item = item.camelize          if item.is_a?(String)
    item = User                   if item == 'Account'
    item = item.safe_constantize  if item.is_a?(String)
    item                          if item.is_a?(Class)
  end

  # Return the name of the model associated with *item*.
  #
  # @param [Any, nil] item             Symbol, String, Class, Model
  #
  # @return [Symbol, nil]
  #
  def self.model_for(item)
    item = item.to_s                    if item.is_a?(Symbol)
    item = item.remove(CONFIG_PREFIX)   if item.is_a?(String)
    item = class_for(item)
    item = item.name.underscore.to_sym  if item.is_a?(Class)
    item = :account                     if item == :user
    item                                if item.is_a?(Symbol)
  end

  # Return the name of the model associated with *item*.
  #
  # @param [Any, nil] item            Symbol, String, Class, Model
  #
  # @return [Symbol, nil]
  #
  def self.for(item)
    model_for(item)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  private

  def self.namespace_for(v)
    v.to_s.underscore.split('/').first
  end

  def self.namespaced?(v)
    return false unless v.is_a?(Symbol) || v.is_a?(String) || v.is_a?(Class)
    v.to_s.match?(%r{::|/})
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Get configured record fields for the indicated model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.config_for(item)
    configuration_fields(item, no_raise: true)
  end

  # Get configured record fields relevant to the given context for the
  # indicated model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  # @param [Symbol]                          action
  #
  # @return [Hash{Symbol=>Hash}, nil]
  #
  def self.context_fields(item, action)
    config_for(item)[action&.to_sym]
  end

  # Get configured record fields relevant to an :index action for the indicated
  # model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.index_fields(item)
    config_for(item)[:index] || EMPTY_CONFIG
  end

  # Get configured record fields relevant to a :show action for the indicated
  # model/controller.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.show_fields(item)
    config_for(item)[:show] || EMPTY_CONFIG
  end

  # Get all configured record fields for the indicated model.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.database_fields(item)
    config_for(item)[:database] || EMPTY_CONFIG
  end

  # Get all configured record fields for the indicated model.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.form_fields(item)
    database_fields(item)
  end

end

__loading_end(__FILE__)
