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

  # A unique identifier for this model instance.
  #
  # @return [String]
  #
  def identifier
    (respond_to?(:id) ? id : object_id).to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configured record fields for each model/controller.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # @see Model::Configuration#configuration_fields
  #
  def self.fields_table
    @fields_table ||= {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Common storage for configured properties for each model/controller.
  #
  module Configuration

    extend self

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Frozen Hash returned as a fall-back for failed configuration lookups.
    #
    # @type [Hash]
    #
    EMPTY_CONFIG = {}.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get configured record fields for a model/controller.
    #
    # @param [Symbol, String, Class, Model, *] type       Model/controller type
    # @param [Boolean]                         no_raise   If *true* return {}
    #
    # @raise [RuntimeError]           If *type* does not map on to a model.
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    # @see Model#fields_table
    #
    def configuration_fields(type, no_raise: false)
      arg  = type
      type = model_for(type) unless type.is_a?(Symbol)
      if type.blank?
        Log.warn((error = "#{__method__}: #{arg}: invalid"))
        raise error unless no_raise
        return EMPTY_CONFIG
      end
      Model.fields_table[type] ||= configured_fields_for(type).deep_freeze
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Combine configuration settings for a given model/controller.
    #
    # @param [Symbol, *] controller
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def configured_fields_for(controller)
      return {} unless controller.is_a?(Symbol)
      model_config = I18n.t("emma.#{controller}", default: {}).deep_dup

      # Start with definitions from config/locales/records/*.yml and apply
      # adjustments from config/locales/controllers/*.yml.
      all_fields = model_config[:record] || {}
      (model_config[:display_fields] || {}).each_pair do |field, entry|
        all_fields[field] = all_fields[field]&.deep_merge(entry) || entry
      end
      all_fields.each_pair do |field, entry|
        all_fields[field] = Field.normalize(entry, field)
      end

      # For pages that specify their own :display_fields section.  If its
      # value is :all or [:all] then all record fields will be displayed on
      # that page.  Otherwise the section may be an array of field
      # specifications; each may be:
      #
      # * String or Symbol - the field name to show
      # * Hash             - table of field names and label overrides
      #
      controller_configs =
        model_config.map { |action, action_entry|
          next unless action_entry.is_a?(Hash)
          next unless action_entry.key?(:display_fields)
          field_list = Array.wrap(action_entry[:display_fields]).dup
          page_fields =
            if field_list.delete(:all)
              all_fields.map { |field, entry|
                next if Field.unused?(entry, action)
                [field, Field.finalize!(entry.deep_dup, field)]
              }.compact.to_h
            end
          page_fields ||= {}
          field_list.each do |field_item|
            field_item = { field_item => nil } unless field_item.is_a?(Hash)
            field_item.each_pair do |field, override|
              field = field.to_sym
              entry = page_fields[field] || all_fields[field]&.deep_dup || {}
              entry.deep_merge!(Field.normalize(override, field)) if override
              page_fields[field] = Field.finalize!(entry, field)
            end
          end
          page_fields.transform_values! { |entry| Field.finalize!(entry) }
          [action, page_fields]
        }.compact.to_h

      # Finalize the generic entries.
      all_fields.transform_values! do |entry|
        Field.finalize!(entry) unless Field.unused?(entry)
      end
      all_fields.compact!

      # Return with the generic field configurations followed by entries for
      # each controller-specific field configuration.
      { all: all_fields }.merge!(controller_configs)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    CONFIG_PREFIX = /^\s*(en\.)?emma\./

    # Return the model class associated with *item*.
    #
    # @param [Symbol, String, Class, Model, *] item
    #
    # @return [Symbol, nil]
    #
    #--
    # noinspection RubyMismatchedReturnType
    #++
    def class_for(item)
      item = item.to_s              if item.is_a?(Symbol)
      item = item.camelize          if item.is_a?(String)
      item = User                   if item == 'Account'
      item = item.safe_constantize  if item.is_a?(String)
      item = item.class             if item.is_a?(Model)
      item = item.base_class        if item.respond_to?(:base_class)
      item                          if item.is_a?(Class)
    end

    # Return the name of the model associated with *item*.
    #
    # @param [Symbol, String, Class, Model, *] item
    #
    # @return [Symbol, nil]
    #
    #--
    # noinspection RubyMismatchedReturnType
    #++
    def model_for(item)
      item = class_for(item) || item           if camelized?(item)
      item = item.class                        if item.is_a?(Model)
      item = item.base_class                   if item.respond_to?(:base_class)
      item = item.name.underscore.to_sym       if item.is_a?(Class)
      item = item.remove(CONFIG_PREFIX).to_sym if item.is_a?(String)
      item = :account                          if item == :user
      item                                     if item.is_a?(Symbol)
    end

    # Get configured record fields for a model/controller.
    #
    # @param [Symbol, String, Class, Model, *] item
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def config_for(item)
      configuration_fields(item, no_raise: true)
    end

    # Get configured record fields relevant to an :index action for a given
    # model.
    #
    # @param [Symbol, String, Class, Model, *] item
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def index_fields(item)
      config_for(item)[:index] || EMPTY_CONFIG
    end

    # Get configured record fields relevant to a :show action for a given
    # model.
    #
    # @param [Symbol, String, Class, Model, *] item
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def show_fields(item)
      config_for(item)[:show] || EMPTY_CONFIG
    end

    # Get all configured record fields for a given model.
    #
    # @param [Symbol, String, Class, Model, *] item
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def database_fields(item)
      config_for(item)[:all] || EMPTY_CONFIG
    end

    # Get all configured record fields for a given model.
    #
    # @param [Symbol, String, Class, Model, *] item
    #
    # @return [Hash{Symbol=>Hash}]    Frozen result.
    #
    def form_fields(item)
      database_fields(item)
        .except(:file_data, :emma_data)
        .merge!(Model::SEARCH_RECORD_FIELDS)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def camelized?(v)
      (v.is_a?(Symbol) || v.is_a?(String)) && (v.to_s == v.to_s.camelize)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    extend self

    # Mapping of label keys to fields from Search::Record::MetadataRecord.
    #
    # @type [Hash{Symbol=>Hash}]
    #
    SEARCH_RECORD_FIELDS =
      database_fields(:entry)[:emma_data]
        .select { |k, v| v.is_a?(Hash) unless k == :cond }
        .deep_freeze

    # Reverse mapping of EMMA search record field to the label configured for
    # it.
    #
    # @type [Hash{String=>Symbol}]
    #
    SEARCH_RECORD_LABELS =
      SEARCH_RECORD_FIELDS
        .transform_values { |v| v[:label] }
        .invert
        .deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.send(:extend, self)
    end

  end

  include Configuration

end

__loading_end(__FILE__)
