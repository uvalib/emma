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
  def entry_fields                                                              # NOTE: from Upload
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
      errors.add(:emma_data, :missing)
    else
      check_required(entry_fields[:emma_data], emma_metadata)
    end
    errors.empty?
  end

  # Compare the source fields against configured requirements.
  #
  # @param [Hash, nil]        required_fields   Default: `#entry_fields`
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
  # @overload enum_methods(required_fields, source)
  #   Check that the given fields are present in the given source object.
  #   @param [Hash]        required_fields
  #   @param [Entry, Hash] source
  #
  def check_required(required_fields = nil, source = nil)                       # NOTE: from Upload
    source  ||= self
    (required_fields || entry_fields).each_pair do |field, entry|
      value = source[field]
      if entry.is_a?(Hash)
        if !value.is_a?(Hash)
          errors.add(field, :invalid, 'expecting Hash')
        elsif value.blank?
          errors.add(field, :missing)
        else
          check_required(value, entry)
        end
      elsif entry[:max] == 0
        # TODO: Should this indicate that the field is *forbidden* instead?
        next
      else
        min = entry[:min].to_i
        max = entry[:max].to_i
        if value.is_a?(Array)
          if value.size < min
            errors.add(field, :too_few, "at least #{min} is required")
          elsif (0 < max) && (max < value.size)
            errors.add(field, :too_many, "no more than #{max} is expected")
          end
        else
          if max != 1
            errors.add(field, :invalid, 'expecting Array')
          elsif !min.zero?
            errors.add(field, :missing)
          end
        end
      end
    end
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
