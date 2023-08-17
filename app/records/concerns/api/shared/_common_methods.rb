# app/records/concerns/api/shared/_common_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General shared methods.
#
module Api::Shared::CommonMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Normalization array handling.
  #
  # :required   Results always given as arrays.
  # :forbidden  Results are only given a singles.
  # :auto       Results given as arrays when indicated; singles otherwise.
  #
  # @type [Array<Symbol>]
  #
  ARRAY_MODES = %i[auto required forbidden].freeze

  # Generic separator for splitting a string into parts.
  #
  # @type [Regexp]
  #
  PART_SEPARATOR = /[|\t\n]+/.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  PRODUCTION_HOST = URI.parse(PRODUCTION_BASE_URL).host.freeze rescue nil

  # Indicate whether this record represents a canonical index entry.
  #
  # In production, for EMMA repository items, this would mean an entry whose
  # :emma_retrievalLink starts with the base URL for the production service.
  #
  # @param [Api::Record, nil] rec  Default: `self`.
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def canonical?(rec = nil)
    rec ||= self
    if (elements = rec.try(:elements))
      elements.all?(&:canonical?)
    else
      local = (rec.try(:emma_repository) == EmmaRepository.default)
      url   = (rec.try(:emma_retrievalLink)   if local)
      host  = (URI.parse(url).host rescue nil if url.present?)
      host.blank? || (host == PRODUCTION_HOST)
    end
  end

  # Indicate whether this record has no field values.
  #
  # @param [Api::Record, nil] rec  Default: `self`.
  #
  def empty?(rec = nil)
    rec ||= self
    if (contained = rec.try(:elements)).nil?
      rec.fields.values.all?(&:blank?)
    else
      contained.blank?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Reduce a string for comparison with another by eliminating surrounding
  # white space and/or punctuation, and by reducing internal runs of white
  # space and/or punctuation to a single space.
  #
  # @param [String]  value
  # @param [Boolean] lowercase        If *false*, preserve case.
  #
  # @return [String]
  #
  def normalized(value, lowercase: true)
    value.to_s.dup.tap do |result|
      result.downcase! if lowercase
      result.sub!(/^[[:space:][:punct:]]+/, '')
      result.sub!(/[[:space:][:punct:]]+$/, '')
      result.gsub!(/[[:space:][:punct:]]+/, ' ')
    end
  end

  # Strip surrounding spaces and terminal punctuation for a proper name,
  # allowing for the possibility of ending with an initial (which needs the
  # trailing '.' to be preserved).
  #
  # @param [String] value
  # @param [Hash]   opt               Passed to #clean.
  #
  # @return [String]
  #
  def clean_name(value, **opt)
    parts = value.strip.split(/[[:space:]]+/)
    parts <<
      case (last = parts.pop)
        when /^[^.]\.$/ then last               # Assumed to be an initial
        when /^[A-Z]$/  then last + '.'         # An initial missing a period.
        else                 clean(last, **opt) # Remove trailing punct.
      end
    parts.join(' ')
  end

  # Strip surrounding spaces and terminal punctuation.
  #
  # @param [String, *] value
  # @param [String]    allowed    Default: #CLEAN_EXCEPT
  # @param [Regexp]    regexp     Default: #CLEAN_REGEXP
  #
  # @return [String, *]
  #
  def clean(value, allowed: nil, regexp: nil, **)
    return value unless value.is_a?(String)
    regexp ||=
      case allowed
        when CLEAN_EXCEPT, nil   then CLEAN_REGEXP
        when CLEAN_EXCEPT_PERIOD then CLEAN_REGEXP_PERIOD
        else                          clean_regexp(allowed)
      end
    value.squish.sub(regexp, '')
  end

  # clean_regexp
  #
  # @param [String] allowed
  #
  # @return [Regexp]
  #
  def self.clean_regexp(allowed)
    allowed = allowed.sub(/([\])-])/, ('\\' + '\1'))
    /([^\w#{allowed}]|\s)+$/
  end

  CLEAN_EXCEPT        = %q(!?'"]\)-).freeze
  CLEAN_EXCEPT_PERIOD = ".#{CLEAN_EXCEPT}".freeze

  CLEAN_REGEXP        = clean_regexp(CLEAN_EXCEPT).freeze
  CLEAN_REGEXP_PERIOD = clean_regexp(CLEAN_EXCEPT_PERIOD).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the first non-blank value given a list of fields.
  #
  # @param [Array<Symbol>] fields
  # @param [Hash]          opt        Passed to #get_values.
  #
  # @return [String, nil]
  #
  def get_value(*fields, **opt)
    get_values(*fields, **opt).first
  end

  # Get the first non-empty value given a list of fields.
  #
  # @param [Array<Symbol>] fields
  # @param [Api::Record]   target     Default: `self`.
  #
  # @return [Array<String>]
  #
  def get_values(*fields, target: nil, **)
    target ||= self
    # noinspection RubyMismatchedReturnType
    fields.find { |meth|
      values = meth && Array.wrap(target.try(meth)).compact_blank
      break values.map(&:to_s) if values.present?
    } || []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A traversal through the hierarchy rooted at the class instance which
  # holds all of the metadata for a single lookup result item.
  #
  # @return [Array<Symbol>]
  #
  def item_record_path
    to_be_overridden
  end

  # item_record
  #
  # @return [Api::Record, nil]
  #
  def item_record
    find_item(*item_record_path)
  end

  # find_record_item
  #
  # @param [Symbol] field
  # @param [Hash]   opt               Passed to #find_item.
  #
  # @return [any, nil]
  #
  def find_record_item(field, **opt)
    find_item(*item_record_path, field, **opt)
  end

  # find_record_items
  #
  # @param [Symbol] field
  # @param [Hash]   opt               Passed to #find_items.
  #
  # @return [Array]
  #
  def find_record_items(field, **opt)
    path = opt.delete(:path) || item_record_path
    if field.is_a?(Array)
      field.flat_map { |f| find_items(*path, f, **opt) }
    else
      find_items(*path, field, **opt)
    end
  end

  # find_record_value
  #
  # @param [Symbol] field
  # @param [Hash]   opt               Passed to #find_value.
  #
  # @return [String, nil]
  #
  def find_record_value(field, **opt)
    find_value(*item_record_path, field, **opt)
  end

  # find_record_values
  #
  # @param [Symbol] field
  # @param [Hash]   opt               Passed to #find_values.
  #
  # @return [Array<String>]
  #
  def find_record_values(field, **opt)
    find_values(*item_record_path, field, **opt)
  end

  # find_item
  #
  # @param [Array<Symbol>] path
  # @param [Symbol]        field
  # @param [Api::Record]   target     Default: `self`.
  # @param [Boolean]       clean      If *true* run result through #clean.
  # @param [Hash]          opt        Passed to #clean.
  #
  # @return [any, nil]
  #
  def find_item(*path, field, target: nil, clean: false, **opt)
    target ||= self
    unless target.respond_to?(field)
      path.each do |part|
        target = target.send(part) if target.respond_to?(part)
        break if target.blank?
      end
    end
    result = target.try(field)&.presence
    if !result || !(clean || opt.present?)
      result
    elsif !result.is_a?(Array)
      clean(result, **opt)
    else
      result.map { |v| clean(v, **opt) }
    end
  end

  # find_items
  #
  # @param [Array<Symbol>] path
  # @param [Symbol]        field
  # @param [Api::Record]   target     Default: `self`.
  # @param [Boolean]       clean      If *true* run result through #clean.
  # @param [Hash]          opt        Passed to #clean.
  #
  # @return [Array]
  #
  def find_items(*path, field, target: nil, clean: false, **opt)
    clean  = true if opt.present?
    result = Array.wrap(find_item(*path, field, target: target))
    result = result.map { |v| clean(v, **opt) } if clean
    result
  end

  # find_value
  #
  # @param [Array<Symbol>] path
  # @param [Symbol]        field
  # @param [String]        separator  Used if the item is an array.
  # @param [Boolean]       clean      If *false* do not #clean.
  # @param [Hash]          opt        Passed to #find_values.
  #
  # @return [String, nil]
  #
  def find_value(*path, field, separator: '; ', clean: true, **opt)
    opt[:clean] = clean
    find_values(*path, field, **opt).presence&.join(separator)
  end

  # find_values
  #
  # @param [Array<Symbol>] path
  # @param [Symbol]        field
  # @param [Boolean]       clean      If *false* do not #clean.
  # @param [Hash]          opt        Passed to #find_items.
  #
  # @return [Array<String>]
  #
  def find_values(*path, field, clean: true, **opt)
    opt[:clean] = clean
    find_items(*path, field, **opt).compact_blank.map!(&:to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the target field value.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Symbol]    field
  #
  # @return [Any]
  #
  def get_field_value(data, field)
    data.is_a?(Hash) ? data[field] : try(field)
  end

  # Set the target field value.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Symbol]    field
  # @param [Any, nil]  value
  #
  # @return [void]
  #
  def set_field_value!(data, field, value)
    value = value.presence
    if !data.is_a?(Hash)
      try("#{field}=", value)
    elsif value
      data[field] = value
    elsif data.key?(field)
      data.delete(field)
    end
  end

  # Update the target field.
  #
  # @param [Hash, nil]   data         Default: *self*.
  # @param [Symbol]      field
  # @param [Symbol, nil] mode         One of #ARRAY_MODES.
  #
  # @return [void]
  #
  # @yield [value] Generate a replacement value
  # @yieldparam [Any] value   The current field value.
  # @yieldreturn [Array]      The new field value(s).
  #
  def update_field_value!(data, field, mode = nil)
    value = get_field_value(data, field)
    array = value.is_a?(Array)
    value = yield(value)
    case mode
      when :required  then # Keep value as array.
      when :forbidden then value = value.first
      else                 value = value.first unless array || value.many?
    end
    set_field_value!(data, field, value)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get the indicated field values from the indicated target.
  #
  # @param [Hash, nil]     data       Default: *self*.
  # @param [Array<Symbol>] fields
  #
  # @return [Array]
  #
  def get_field_values(data, *fields)
    v = data.is_a?(Hash) ? data.values_at(*fields) : fields.map { |f| try(f) }
    v.map(&:presence)
  end

  # Update the indicated target with the given values.
  #
  # @param [Hash, nil] data           Default: *self*.
  # @param [Hash]      values
  #
  # @return [void]
  #
  def set_field_values!(data, values)
    if data.is_a?(Hash)
      deletions = values.select { |_, v| v.blank? }.keys.presence
      values.except!(*deletions) if deletions
      data.except!(*deletions)   if deletions
      data.merge!(values)
    else
      values.each_pair { |k, v| try("#{k}=", v) }
    end
  end

end

__loading_end(__FILE__)
