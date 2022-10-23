# app/models/record/validatable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Class methods for validating records.
#
module Record::Validatable

  extend ActiveSupport::Concern

  include Record

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveRecord::Validations
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Control whether field validation should occur.                              # NOTE: from Upload
  #
  # NOTE: Not currently supported
  #
  # @type [Boolean]
  #
  FIELD_VALIDATION = false

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configured requirements for Entry fields.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def database_fields                                                           # NOTE: from Upload
    Model.database_fields(:entry)
  end

  # Indicate whether all required fields have valid values.
  #
  def required_fields_valid?                                                    # NOTE: from Upload
    check_required
    errors.empty?
  end

  # Indicate whether all required fields have valid values.
  #
  def emma_data_valid?                                                          # NOTE: from Upload
    if emma_data.blank?
      error(:emma_data, :missing)
    else
      check_required(database_fields[:emma_data], emma_metadata)
    end
    errors.empty?
  end

  # Compare the source fields against configured requirements.
  #
  # @param [Hash, nil]        required_fields   Default: `#database_fields`
  # @param [Entry, Hash, nil] source            Default: self.
  #
  # @return [void]
  #
  #--
  # == Variations
  #++
  #
  # @overload check_required
  #   Check that all configured fields are present in the current record.
  #   @param [Hash]        required_fields
  #
  # @overload check_required(required_fields)
  #   Check that the given fields are present in the current record.
  #   @param [Hash]        required_fields
  #
  # @overload check_required(required_fields, source)
  #   Check that the given fields are present in the given source object.
  #   @param [Hash]        required_fields
  #   @param [Entry, Hash] source
  #
  def check_required(required_fields = nil, source = nil)                       # NOTE: from Upload
    source ||= self
    (required_fields || database_fields).each_pair do |field, config|
      value      = source[field]
      min, max   = config.values_at(:min, :max).map(&:to_i)
      nested_cfg = config.except(:cond).select { |_, v| v.is_a?(Hash) }
      if nested_cfg.present?
        value ||= {}
        if value.is_a?(Hash)
          check_required(nested_cfg, value)
        else
          error(field, :invalid, "expecting Hash; got #{value.class}")
        end

      elsif config[:required] && value.blank?
        error(field, :missing, 'required field')

      elsif config[:max] == 0
        error(field, :invalid, 'max == 0') if value.present?

      elsif config[:type].to_s.include?('json')
        unless value.nil? || value.is_a?(Hash)
          error(field, :invalid, "expecting Hash; got #{value.class}")
        end

      elsif value.is_a?(Array)
        too_few  = min.positive? && (value.size < min)
        too_many = max.positive? && (value.size > max)
        error(field, :too_few,  "at least #{min} is required")    if too_few
        error(field, :too_many, "no more than #{max} is allowed") if too_many

      elsif value.blank?
        error(field, :missing)                    unless min.zero?

      elsif database_columns[field]&.array
        error(field, :invalid, 'expecting Array') unless max == 1
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def error(field, type, message = nil)
    opt = { message: message }.compact
    errors.add(field, type, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::Validations
      # :nocov:
    end

    # =========================================================================
    # :section: ActiveRecord validations
    # =========================================================================

    validate(on: %i[create]) { required_fields_valid? } if FIELD_VALIDATION
    validate(on: %i[update]) { required_fields_valid? } if FIELD_VALIDATION

  end

end

__loading_end(__FILE__)
