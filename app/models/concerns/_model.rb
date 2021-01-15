# app/models/concerns/_model.rb
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
    instance_variables.map { |v| v.to_s.delete_prefix('@').to_sym }.sort
  end

  # The fields and values for this model instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  def fields
    field_names.map { |field|
      [field, send(field)] rescue nil
    }.compact.to_h
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

  # Common storage for configured properties for each model/controller.
  #
  class << self

    # Get configured record fields for a model and controller.
    #
    # @param [Symbol, String] type    Model/controller type.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def configured_fields(type)
      type = type.delete_prefix('emma.').to_sym if type.is_a?(String)
      configured_fields_table[type] ||= configured_fields_for(type)
    end

    # Configured record fields for each model/controller.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def configured_fields_table
      @configured_fields_table ||= {}
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Combine configuration settings for a given model/controller.
    #
    # @param [Symbol, String] controller
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def configured_fields_for(controller)
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
      controller_configs

      # Finalize the generic entries.
      all_fields.transform_values! do |entry|
        Field.finalize!(entry) unless Field.unused?(entry)
      end
      all_fields.compact!

      # Return with the generic field configurations followed by entries for
      # each controller-specific field configuration.
      { all: all_fields }.merge!(controller_configs)
    end

  end

end

__loading_end(__FILE__)
