# app/models/concerns/file_format.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for remediated file types.
#
# A class including this module is required to have the following constants
# defined:
#
#   :FORMAT_FIELDS        Hash{Symbol=>Proc,Symbol}
#   :FIELD_TRANSFORMS     Hash{Symbol=>Hash{Symbol=>Proc,Symbol}}
#   :FIELD_ALWAYS_ARRAY   Array<Symbol>
#
# @see FileAttributes
#
module FileFormat

  include Emma::Unicode
  include FileAttributes

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Known format types.
  #
  # @type [Array<Symbol>]
  #
  TYPES = I18n.t('emma.format').keys.map(&:to_sym).freeze

  # Placeholder for an unknown format.
  #
  # @type [String]
  #
  FORMAT_MISSING = '???'

  # Separator between values of a multi-valued field.
  #
  # @type [String]
  #
  FILE_FORMAT_SEP = "#{EN_SPACE}#{BLACK_CIRCLE}#{EN_SPACE}"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # FIELD_TRANSFORMS
  #
  # @type [Hash{Symbol=>Hash{Symbol=>Proc,Symbol}}]
  #
  # @see #field_transforms
  #
  FIELD_TRANSFORMS = {
    field: {
      Date:             :format_date,
      CopyrightDate:    :format_date,
      CreationDate:     :format_date_time,
      ModifiedDate:     :format_date_time,
      ProductionDate:   :format_date_time,
      PublicationDate:  :format_date,
      RevisionDate:     :format_date_time,
      SourceDate:       :format_date_time,
      SubmissionDate:   :format_date_time,
      Language:         ->(values) { normalize_language(values) },
    }
  }.deep_freeze

  # File format fields whose values should be provided as an array even if
  # there is only a single value element.
  #
  # @type [Array<Symbol>]
  #
  # @see #field_value_array
  #
  FIELD_ALWAYS_ARRAY = %i[
    AccessibilityControl
    AccessibilityFeature
    AccessibilityHazard
    AccessMode
    AccessModeSufficient
    Author
    Contributor
    CoverImage
    Creator
    Keywords
    Subject
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # configuration
  #
  # @return [Hash{Symbol=>String,Array,Hash}]
  #
  def configuration
    raise "#{self.class}: #{__method__} not defined"
  end

  # parser
  #
  # @return [FileParser]
  #
  def parser
    raise "#{self.class}: #{__method__} not defined"
  end

  # parser_metadata
  #
  # @return [*]                       Type is specific to the subclass.
  #
  def parser_metadata
    @parser_metadata ||= parser.metadata
  end

  # Metadata extracted from the file format instance.
  #
  # @return [Hash]
  #
  def metadata
    @metadata ||= format_metadata(parser_metadata)
  end

  # Extracted metadata mapped to common metadata fields.
  #
  # @return [Hash{Symbol=>*}]
  #
  def common_metadata
    @common_metadata ||= mapped_metadata(parser_metadata)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Metadata extracted from the file format instance.
  #
  # @param [*] info                   Information supplied by the subclass.
  #
  # @yield field accessor label values  Per-field processing by caller.
  # @yieldparam [Symbol]              field
  # @yieldparam [Symbol, Proc, Array] accessor
  # @yieldparam [String]              label
  # @yieldparam [Array<String>]       values
  # @yieldreturn [Array<(String,Array)>]  label, values
  #
  # @return [Hash{String=>*}]
  #
  def format_metadata(info)
    return {} if info.blank?
    # @type [Symbol]      field
    # @type [Symbol,Proc] accessor
    format_fields.map { |field, accessor|
      value = apply_field_accessor(info, accessor)
      next if value.blank?
      value = apply_field_transform(:field, field, value)
      value = apply_field_transform(:accessor, accessor, value)
      label = field.to_s.titleize
      label, value = yield(field, accessor, label, value) if block_given?
      label = label.pluralize if value.size > 1
      unless field_value_array.include?(field)
        value = value.join(field_value_separator)
      end
      [label, value]
    }.compact.to_h
  end

  # Map metadata extracted from the file format instance into common metadata
  # fields.
  #
  # @param [*] info                   Information supplied by the subclass.
  #
  # @return [Hash{Symbol=>*}]
  #
  def mapped_metadata(info)
    return {} if info.blank?
    # @type [Symbol] format_field
    # @type [Symbol] mapped_field
    mapped_metadata_fields.map { |format_field, mapped_field|
      value = apply_field_accessor(info, format_field)
      next if value.blank?
      key   = mapped_field
      value = apply_field_transform(:accessor, format_field, value)
      [key, value]
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # apply_field_accessor
  #
  # @param [*]                   info
  # @param [Symbol, Proc, Array] accessor
  #
  # @return [Array<String>]
  #
  def apply_field_accessor(info, accessor)
    result =
      case accessor
        when Array
          accessor.find do |a|
            v = apply_field_accessor(info, a)
            break v if v.present?
          end
        when Proc
          accessor.call(info)
        else
          info.send(accessor)
      end
    Array.wrap(result).reject(&:blank?)
  end

  # apply_field_transform
  #
  # @param [Symbol]        type
  # @param [Symbol, Proc]  key
  # @param [Array<String>] value
  #
  # @return [Array<String>]
  #
  def apply_field_transform(type, key, value)
    method =
      field_transforms[type]&.find do |k, v|
        break v if k.is_a?(Regexp) ? (key.to_s =~ k) : (key == k)
      end
    case method
      when Symbol then transform(method, value)
      when Proc   then method.call(value)
      else             value
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Separator between values of a multi-valued field.
  #
  # @return [String]
  #
  def field_value_separator
    FILE_FORMAT_SEP
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # format_fields
  #
  # @return [Hash{Symbol=>Proc,Symbol}]
  #
  def format_fields
    @format_fields ||= self.class_eval { const_get(:FORMAT_FIELDS) }
  end

  # field_transforms
  #
  # @return [Hash{Symbol=>Hash{Symbol=>Proc,Symbol}}]
  #
  def field_transforms
    FIELD_TRANSFORMS
  end

  # Fields whose values should be provided as an array even if there is only a
  # single value element.
  #
  # @return [Array<Symbol>]
  #
  def field_value_array
    FIELD_ALWAYS_ARRAY
  end

  # mapped_metadata_fields
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  def mapped_metadata_fields
    @mapped_metadata_fields ||= self.class_eval { const_get(:FIELD_MAP) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # format_date
  #
  # @param [String, Date, DateTime] value
  #
  # @return [String]
  #
  def format_date(value)
    value = value.to_date if value.is_a?(DateTime)
    value = Date.parse(value) rescue value if value.is_a?(String)
    value.to_s
  end

  # format_date_time
  #
  # @param [String, Date, DateTime] value
  #
  # @return [String]
  #
  def format_date_time(value)
    value = DateTime.parse(value) rescue value if value.is_a?(String)
    if value.is_a?(DateTime)
      value.strftime('%F %R').sub(/ 00:00$/, '')
    else
      format_date(value)
    end
  end

  # format_image
  #
  # @param [String] _value
  #
  # @return [String]
  #
  def format_image(_value)
    raise "#{self.class}: #{__method__} not defined"
  end

  # normalize_language
  #
  # @param [Array<String>] values
  #
  # @return [Array<String>]
  #
  def self.normalize_language(values)
    values.map { |v|
      v.match?(/^[a-z]{2}$/) && ISO_639.search(v).first&.alpha3 || v
    }.uniq
  end

  # Used within #field_transforms to apply a method to each element of a
  # value whether it is a scalar or an array.
  #
  # @overload transform(method, value)
  #   @param [Symbol]        method
  #   @param [Array<String>] value
  #   @return [Array<String>]
  #
  # @overload transform(method, value)
  #   @param [Symbol] method
  #   @param [String] value
  #   @return [String]
  #
  def transform(method, value)
    if value.is_a?(Array)
      value.map { |v| send(method, v) }
    else
      send(method, value)
    end
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  module ModuleMethods

    # Get configured properties for a file format.  If multiple sections are
    # given each successive section is recursively merged into the previous.
    #
    # @param [Array<String, Symbol, Hash>] section
    #
    # @return [Hash{Symbol=>String,Array,Hash}]
    #
    def format_configuration(*section)
      type = section.last
      if type.is_a?(String)
        type = type.sub(/^emma\./, '') if type.start_with?('emma.')
        type = type.to_sym
      end
      return {} unless type.is_a?(Symbol)
      @@format_configuration ||= {}
      @@format_configuration[type] ||=
        {}.tap do |result|
          section.each do |sec|
            # noinspection RubyYardParamTypeMatch
            hash = sec.is_a?(Hash) ? sec : format_configuration_section(sec)
            result.deep_merge!(hash) if hash.present?
          end
        end
    end

    # Get properties from a configuration section.
    #
    # @param [String, Symbol] section
    #
    # @return [Hash{Symbol=>String,Array,Hash}]
    #
    def format_configuration_section(section)
      path = section.to_s
      path = path.start_with?('emma.') ? path : "emma.#{path}"
      hash = I18n.t(path).deep_dup
      %i[mimes exts].each do |key|
        hash[key] ||= []
        hash[key].map! { |s| s.to_s.strip.downcase.presence }
        hash[key].compact!
      end
      %i[fields map].each do |key|
        hash[key] ||= {}
        hash[key].transform_values! do |value|
          if value.is_a?(Array)
            value.map { |s| s.to_s.strip.to_sym.presence }.compact.presence
          else
            value.to_s.strip.to_sym.presence
          end
        end
        hash[key].compact!
      end
      hash
    end

  end

  def self.included(base)
    base.send(:extend, ModuleMethods)
  end

end

__loading_end(__FILE__)
