# app/models/concerns/import.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common bulk import methods.
#
module Import

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The prefix applied to imported field names that have not otherwise been
  # assigned a field name to be used within :emma_data.
  #
  # @type [String]
  #
  DEFAULT_NAME_PREFIX = 'x_'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Convert imported data fields.
  #
  # @param [Hash] fields
  #
  # @return [Hash]
  #
  # == Usage Notes
  # The caller should take care to ensure that *fields* only contains import
  # fields; if database attributes, or :file_data/:emma_data fields appear here
  # they will be treated as import fields to which the default transformation
  # will be applied.
  #
  def translate_fields(fields)
    result = {}
    # @type [Symbol, String] k
    # @type [String, nil]    v
    fields.flat_map { |k, v|
      k, v = resolve(k, v)
      pairs = []
      if k.is_a?(Array)
        k.each_with_index { |key, idx| pairs << [key, v[idx]] }
      elsif k.present?
        pairs << [k, v]
      end
      pairs
    }.each { |k, v|
      result[k] = [*result[k], *v] if k.present? && v.present?
    }
    result = reject_blanks(result).transform_values!(&:uniq)
    normalize_results(result)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Import schema.
  #
  # @return [Hash]
  #
  def schema
    not_implemented 'to be overridden by the subclass'
  end

  # String prepended to an imported data key which turns it into a key that can
  # be included in data storage.
  #
  # @return [String]
  #
  def name_prefix
    DEFAULT_NAME_PREFIX
  end

  # Translate an import field name to a destination field name.
  #
  # @param [Symbol, String] k
  # @param [String]         prefix
  #
  # @return [Symbol]
  #
  def default_name(k, prefix = name_prefix)
    k = k.to_s
    if prefix.blank?
      k = k.camelize(:lower)
    else
      prefix = "#{prefix}_" unless prefix.end_with?('_')
      k = k.delete_prefix(prefix).camelize(:lower).prepend(prefix)
    end
    k.to_sym
  end

  # Transform a value into a name that can be used as a symbolized hash key.
  #
  # @param [*] v
  #
  # @return [Symbol]
  #
  def hash_key(v)
    v.to_s.squish.downcase.tr('^a-z0-9', '_').to_sym
  end

  # ===========================================================================
  # :section: Value transforms
  # ===========================================================================

  public

  # Transform a data item.
  #
  # Strings containing ";" are interpreted as multi-valued items; these are
  # transformed into an array.
  #
  # Arrays without multiple items are transformed into strings.
  #
  # @param [*] v
  #
  # @return [Array, String, Integer, Boolean, nil]
  #
  def values(v)
    v = v.split(/\s*;\s*/) if v.is_a?(String) && v.include?(';')
    v = v.compact_blank    if v.is_a?(Array)
    v = v.first            if v.is_a?(Array)  && (v.size <= 1)
    v.presence
  end

  # Transform a data item into an array unconditionally.
  #
  # @param [*] v
  #
  # @return [Array]
  #
  # @yield [element] Allow replacement of each array element.
  # @yieldparam [String] element
  # @yieldreturn [String] The replacement element.
  #
  def array_value(v, &block)
    array = Array.wrap(values(v)).compact_blank
    array.map!(&block).compact! if block
    array
  end

  # Transform a data item into a string.
  #
  # @param [*]      v
  # @param [String] join              Connector if *v* is an array.  If *join*
  #                                     is set to *nil* then only the first
  #                                     array element is selected.
  # @param [Boolean] first            If *true* then only the first array
  #                                     element is selected.
  #
  # @return [String, nil]
  #
  def string_value(v, join: ';', first: false)
    if v.is_a?(Array)
      v = v.compact_blank
      v = (first || !join) ? v.first : v.join(join)
    end
    v.to_s.strip.presence
  end

  # Transform a data item into a counting number (1 or greater).
  #
  # @param [*] v
  #
  # @return [Integer, nil]
  #
  def ordinal_value(v)
    v = string_value(v)
    positive(v)
  end

  # Transform a date data item into a four-digit year.
  #
  # @param [String] v
  #
  # @return [String, nil]
  #
  def year_value(v)
    year = string_value(v)
    return year if year.nil? || year.match?(/^\d{4}$/)
    date = Date.parse(year) rescue return
    '%04d' % date.year
  end

  # Transform a data item into one or more three-character ISO 639 values.
  #
  # @param [*] v
  #
  # @return [Array<String>]
  #
  def language_values(v)
    array_value(v) { |lang| IsoLanguage.find(lang)&.alpha3 || lang }
  end

  # Transform a data item into one or more DOI identifiers.
  #
  # @param [*] v
  #
  # @return [Array<String>]
  #
  def doi_values(v)
    identifier_values(v, 'doi:')
  end

  # Transform a data item into one or more ISBN identifiers.
  #
  # @param [*] v
  #
  # @return [Array<String>]
  #
  def isbn_values(v)
    identifier_values(v, 'isbn:')
  end

  # Transform a data item into one or more ISSN identifiers.
  #
  # @param [*] v
  #
  # @return [Array<String>]
  #
  def issn_values(v)
    identifier_values(v, 'issn:')
  end

  # Transform a data item into one or more LCCN identifiers.
  #
  # @param [*] v
  #
  # @return [Array<String>]
  #
  def lccn_values(v)
    identifier_values(v, 'lccn:')
  end

  # Transform a data item into one or more identifiers of the form expected by
  # :dc_identifier and :dc_relation.
  #
  # @param [*]             v
  # @param [String, #to_s] prefix
  #
  # @return [Array<String>]
  #
  def identifier_values(v, prefix)
    return [] if v.blank?
    id_type = prefix = prefix.to_s.strip
    if prefix.end_with?(':')
      id_type = prefix.sub(/\s*:$/, '')
    elsif prefix.present?
      prefix  = "#{prefix}:"
    end
    array_value(v) do |id|
      next id unless id.is_a?(String)
      id = id.strip
      next id unless prefix.present?
      id = id.delete_prefix(id_type).lstrip if id.start_with?(id_type)
      "#{prefix}#{id}"
    end
  end

  # Transform a data item into an EnumType value.
  #
  # @param [*]     v
  # @param [Class] type               A subclass of EnumType.
  #
  # @return [String, nil]
  #
  def enum_value(v, type)
    val = string_value(v, first: true)
    return if val.blank?
    key = hash_key(val).to_s
    type.pairs.find do |name, label|
      return name if name.casecmp?(key) || label.casecmp?(val)
    end
  end

  # Transform a data item into an array of EnumType values.
  #
  # @param [*]     v
  # @param [Class] type               A subclass of EnumType.
  #
  # @return [Array<String>]
  #
  def enum_values(v, type)
    array_value(v) { |item| enum_value(item, type) }
  end

  # ===========================================================================
  # :section: Field/value transforms
  # ===========================================================================

  public

  # Referenced in the schema as a translation target that indicates that the
  # associated import field should be skipped and not included in data stored
  # in the record.
  #
  # @param [*] k                      Imported field being skipped.
  # @param [*] v
  #
  # @return [Array<(nil,nil)>]
  #
  def skip(k = nil, v = nil)
    __debug_import(__method__, k, v)
    return nil, nil
  end

  # Default transformation.
  #
  # @param [Symbol, String] k
  # @param [*]              v
  # @param [String]         prefix
  #
  # @return [Array<(Symbol,Any)>]
  # @return [Array<(Symbol,Array)>]
  #
  def default(k, v, prefix = name_prefix)
    __debug_import(__method__, k, v)
    k = default_name(k, prefix)
    v = values(v)
    return k, v
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Normalize single-element arrays to scalar values and sort the fields for
  # easier comparison when reviewing/debugging.
  #
  # @param [Hash] fields
  #
  # @return [Hash]
  #
  def normalize_results(fields)
    fields.transform_values! do |v|
      (v.is_a?(Array) && (v.size <= 1)) ? v.first : v
    end
  end

  # Apply the appropriate method for the given import field.
  #
  # @param [Symbol, String] k         Import field name.
  # @param [*]              v         Import field value.
  #
  # @return [Array<(Symbol,Any)>]
  #
  def resolve(k, v)
    k     = k.to_sym
    field = schema[k]
    if field.is_a?(Array)
      meth  = field.last
      field = field.first
      value = meth.is_a?(Proc) ? meth.call(v) : send(meth, v)
      return field, value
    elsif field && respond_to?(field)
      send(field, k, v)
    elsif field.is_a?(Symbol)
      return field, values(v)
    else
      return default_name(k), values(v)
    end
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  public

  # get_importer
  #
  # @param [Module, String, Symbol] mod
  #
  # @return [Module, nil]
  #
  def self.get_importer(mod)
    arg = mod
    mod = mod.to_s if mod.is_a?(Symbol)
    if mod.is_a?(String)
      mod = "Import::#{mod.camelize}" unless mod.start_with?('Import::')
      mod = mod.safe_constantize
    end
    # noinspection RubyMismatchedReturnType
    return mod if mod.is_a?(Module)
    Log.error(__method__) { "#{arg}: invalid importer" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  if not DEBUG_IMPORT

    def __debug_import(...); end

  else

    include Emma::Debug::OutputMethods

    # __debug_import
    #
    # @param [String, Symbol] label
    # @param [*]              k
    # @param [*]              v
    #
    # @return [nil]
    #
    def __debug_import(label, k, v)
      label = label.to_s.upcase
      __debug_line('import', label, leader: ',,,,,,,,,,') do
        { k: k, v: v }
      end
    end

  end

end

__loading_end(__FILE__)
