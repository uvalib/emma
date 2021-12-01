# app/models/concerns/model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common model methods.
#
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

  # Indicate whether the including class is actually a composite of one or more
  # Model instances.
  #
  def aggregate?
    false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether *name* is a field defined by this model.
  #
  # @param [Symbol, String]
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
  # @return [Hash{Symbol=>*}]
  #
  def fields
    if is_a?(ApplicationRecord)
      attributes.symbolize_keys
    else
      field_names.map { |field| [field, send(field)] rescue nil }.compact.to_h
    end
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
  # @param [Symbol, String, Class, Model, *] type       Model/controller type
  # @param [Boolean]                         no_raise   If *true* return {}
  #
  # @raise [RuntimeError]             If *type* does not map on to a model.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.configuration_fields(type, no_raise: false)
    arg  = type
    type = model_for(type) unless type.is_a?(Symbol)
    if type.blank?
      Log.warn((error = "#{__method__}: #{arg}: invalid"))
      raise error unless no_raise
      return EMPTY_CONFIG
    end
    fields_table[type] ||= configured_fields_for(type).deep_freeze
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Keys under "emma.*.record" beginning with an underscore, which represent
  # control directives and not record fields.
  #
  # @type [Array<Symbol>]
  #
  DIRECTIVES = [

    # Keys under "emma.*.record" beginning with an underscore, which represent
    # the control directive for specifying the base configuration.
    #
    # @type [Array<Symbol>]
    #
    BASE_DIRECTIVE = %i[base base_config base_configuration].freeze

  ].flatten.freeze

  # Configured record fields for each model/controller.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.fields_table
    @fields_table ||= {}
  end

  # Combine configuration settings for a given model/controller.
  #
  # @param [Symbol, *] type
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def self.configured_fields_for(type)
    return {} unless type.is_a?(Symbol)
    model_config = I18n.t("emma.#{type}", default: {}).deep_dup

    # Start with definitions from config/locales/records/*.yml, separating
    # control directives from field name entries.
    directives = {}
    all_fields = model_config[:record] || {}
    all_fields.each_pair do |field, entry|
      name = field.to_s.sub!(/^_/, '')&.to_sym
      if name && DIRECTIVES.include?(name)
        directives[name] = entry
      elsif name
        Log.info { "#{__method__}(#{type}): #{name}: unexpected directive" }
      end
      all_fields[field] = (Field.normalize(entry, field) unless name)
    end
    all_fields.compact!

    # Special handling so that "emma.search.record" entries are initialized
    # with the equivalent values from the submission record configuration.
    if directives.present?
      if (base = directives.values_at(*BASE_DIRECTIVE).first).present?
        base = base.values_at(:record, :field) if base.is_a?(Hash)
        base_config, base_field = Array.wrap(base).map(&:to_sym)
        base_config = configuration_fields(base_config)&.dig(:all)
        base_config = base_field.present? && base_config&.dig(base_field) || {}
        all_fields.each_pair do |field, entry|
          all_fields[field] = base_config[field].deep_merge(entry)
        end
      end
    end

    # Apply adjustments from config/locales/controllers/*.yml then finalize
    # the generic entries.
    (model_config[:display_fields] || {}).each_pair do |field, entry|
      entry = Field.normalize(entry, field)
      all_fields[field] = all_fields[field]&.deep_merge(entry) || entry
    end
    all_fields.transform_values! { |entry| Field.finalize!(entry) }
    all_fields.delete_if { |_, entry| Field.unused?(entry) }

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
          field_entry.symbolize_keys.each_pair do |field, override|
            next if page_fields[field] && !override
            override &&= Field.normalize(override, field)
            entry = page_fields[field] || all_fields[field]&.deep_dup
            entry = override && entry&.deep_merge!(override) || override || {}
            entry = Field.finalize!(entry)
            page_fields[field] = (entry unless Field.unused?(entry))
          end
        end
        # noinspection RubyNilAnalysis
        page_fields.compact!
        [action, page_fields]
      }.compact.to_h

    # Return with the generic field configurations followed by entries for
    # each model/controller-specific field configuration.
    { all: all_fields }.merge!(controller_configs)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # @private
  CONFIG_PREFIX = /^\s*(en\.)?emma\./

  # Return the model class associated with *item*.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Class, nil]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
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
  # @param [Symbol, String, Class, Model, *] item
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
  # @param [Symbol, String, Class, Model, *] item
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
  # @return [Hash{Symbol=>Hash}]        Frozen result.
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
    config_for(item)[:all] || EMPTY_CONFIG
  end

  # Get all configured record fields for the indicated model.
  #
  # @param [Symbol, String, Class, Model, *] item
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def self.form_fields(item)
    database_fields(item)
      .except(:file_data, :emma_data)
      .merge!(Model::SEARCH_RECORD_FIELDS)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Mapping of label keys to fields from Search::Record::MetadataRecord.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  SEARCH_RECORD_FIELDS = config_for(:search)[:all]

end

__loading_end(__FILE__)
