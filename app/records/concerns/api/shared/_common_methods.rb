# app/records/concerns/api/shared/_common_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'

# General shared methods.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module Api::Shared::CommonMethods

  include Emma::Common

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
  PRODUCTION_HOST = URI.parse(PRODUCTION_URL).host.freeze rescue nil

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
      local = EmmaRepository.default?(rec.try(:emma_repository))
      url   = (rec.try(:emma_retrievalLink).presence   if local)
      host  = (URI.parse(url).host.presence rescue nil if url)
      host.nil? || (host == PRODUCTION_HOST)
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
  # @param [any, nil] value           String
  # @param [String]   allowed         Default: #CLEAN_EXCEPT
  # @param [Regexp]   regexp          Default: #CLEAN_REGEXP
  #
  # @return [String, any, nil]
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

  CLEAN_EXCEPT        = %q{!?'"])-}.freeze
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

  # HTML elements accepted by #CONTENT_SANITIZE.
  #
  # @type [Array<String>]
  #
  ALLOWED_ELEMENTS = %w[
    b
    br
    em
    i
    strong
    sub
    sup
  ].freeze

  # Sanitizer for catalog title contents.
  #
  # @type [Sanitize]
  #
  SANITIZE = Sanitize.new(elements: ALLOWED_ELEMENTS)

  # Return HTML with elements limited to #ALLOWED_ELEMENTS.
  #
  # @param [String] value
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def sanitized(value)
    SANITIZE.fragment(value).html_safe
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
    must_be_overridden
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
    find = ->(fld) { find_items(*path, fld, **opt) }
    field.is_a?(Array) ? field.flat_map(&find) : find.(field)
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
      result.map { clean(_1, **opt) }
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
    result = result.map { clean(_1, **opt) } if clean
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
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  # @param [Symbol]                 field
  #
  # @return [any, nil]
  #
  def get_field_value(data, field)
    data.is_a?(Hash) ? data[field] : try(field)
  end

  # Set the target field value.
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  # @param [Symbol]                 field
  # @param [any, nil]               value
  #
  # @return [void]
  #
  def set_field_value!(data, field, value)
    value = value.presence
    if data.is_a?(Hash)
      if value
        data[field] = value
      else
        data.delete(field)
      end
    else
      if respond_to?((meth = :"#{field}="))
        send(meth, value)
      else
        Log.warn do
          "#{__method__}: #{field}: unexpected #{value.class} #{value.inspect}"
        end
      end
    end
  end

  # Update the target field.
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  # @param [Symbol]                 field
  # @param [Symbol, nil]            mode    One of #ARRAY_MODES.
  # @param [Integer, nil]           limit   Limit the number of array values.
  #
  # @return [void]
  #
  # @yield [value] Generate a replacement value
  # @yieldparam [Array] values        The current field value.
  # @yieldreturn [any, nil]           The new field value(s).
  #
  def update_field_value!(data, field, mode: nil, limit: nil, **)
    value = get_field_value(data, field)
    array = value.is_a?(Array)
    value = Array.wrap(value)
    # noinspection RubyMismatchedArgumentType
    value = value.take(limit) if non_negative(limit)
    value = Array.wrap(yield(value) || value) if block_given?
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
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  # @param [Array<Symbol>]          fields
  #
  # @return [Array]
  #
  def get_field_values(data, *fields)
    if data.is_a?(Hash)
      data.values_at(*fields).map!(&:presence)
    else
      fields.map { try(_1).presence }
    end
  end

  # Update the indicated target with the given values.
  #
  # @param [Api::Record, Hash, nil] data    Default: *self*.
  # @param [Hash]                   values
  #
  # @return [void]
  #
  def set_field_values!(data, values)
    if data.is_a?(Hash)
      deletions = values.select { |_, v| v.blank? }.keys
      data.merge!(values).except!(*deletions)
    else
      values.each_pair { |field, value| try("#{field}=", value) }
    end
  end

end

__loading_end(__FILE__)
