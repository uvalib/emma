# app/records/concerns/api/shared/transform_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting transformations of data fields.
#
module Api::Shared::TransformMethods

  include Api::Shared::IdentifierMethods
  include Api::Shared::DateMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform data fields.
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  #
  # @return [void]
  #
  def normalize_data_fields!(data = nil)
    normalize_identifier_fields!(data)
    clean_dc_relation!(data)
    normalize_title_dates!(data)
    api_transitions!(data)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Old ("deprecated") fields paired with the new field name.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  RENAMED_FIELDS =
    ApiMigrate::configuration.transform_values { |v|
      v[:new_name]&.to_sym
    }.compact_blank!.freeze

  # Back-fill "deprecated" fields.
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  #
  # @return [void]
  #
  def api_transitions!(data = nil)
    values =
      RENAMED_FIELDS.map { |old_field, new_field|
        old_value, new_value = get_field_values(data, old_field, new_field)
        if old_value && new_value.blank?
          [new_field, old_value]
        elsif new_value && old_value.blank?
          [old_field, new_value]
        end
      }.compact
    set_field_values!(data, values.to_h) if values.present?
  end

end

__loading_end(__FILE__)
