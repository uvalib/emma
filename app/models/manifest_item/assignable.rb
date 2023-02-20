# app/models/manifest_item/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Assignable

  include ManifestItem::Config
  include ManifestItem::Validatable

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Assignable
    include Record::InstanceMethods
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Pattern by which strings are split into arrays.
  #
  # @type [String,Regexp]
  #
  LINE_SPLIT = /[;\n]+/

  # String by which arrays are combined into strings.
  #
  # @type [String,RegExp]
  #
  LINE_JOIN = ";\n"

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Ensure that blanks are allowed and that input values are normalized.
  #
  # @param [Hash, nil] attr
  # @param [Hash, nil] opt
  #
  # @option opt [Boolean] :invalid    Allow invalid values.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def attribute_options(attr, opt = nil)
    n_opt, opt = partition_hash(opt, :invalid, :nil_default)
    opt.reverse_merge!(compact: false, key_norm: true)
    attr = super(attr, opt)
    attr = default_attributes(attr)
    attr.map { |k, v|
      next [k, nil] unless v.present? || v.is_a?(FalseClass)

      column = database_columns[k]
      field  = database_fields[k]
      type   = field[:type]
      v_orig = v

      if column.array || field[:array] || (type == 'textarea')
        case v
          when Array  then v = v.dup
          when Symbol then v = v.to_s
          when String then v = v.strip.split(LINE_SPLIT)
          else             Log.warn "#{__method__}: type #{v.class} unexpected"
        end
        v = Array.wrap(v)
        v.map! { |e|
          e = normalize_single(e, type, **n_opt)
          e.is_a?(FalseClass) ? e : e.presence
        }.compact!
        v = v.join(LINE_JOIN) unless column.array
      elsif k == :file_data
        v = normalize_file(v, **n_opt).presence
      elsif k == :dcterms_dateCopyright
        v = normalize_copyright(v, **n_opt)
      else
        v = normalize_single(v, type, **n_opt)
      end

      Log.warn {
        "#{__method__}: #{v_orig.class} unexpected; ignored #{v_orig.inspect}"
      } if v.nil?

      [k, v] unless v.nil?
    }.compact.to_h
  end

  # A mapping of key comparison value to actual database column name.
  #
  # @return [Hash{String=>Symbol}]
  #
  def key_mapping
    # noinspection RubyMismatchedReturnType
    @key_mapping ||= super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Include the default repository value if not specified.
  #
  # @param [Hash, nil] attr
  #
  # @return [Hash]
  #
  def default_attributes(attr = nil)
    attr = attr&.dup || {}
    attr[:repository] ||= EmmaRepository.default unless ALLOW_NIL_REPOSITORY
    # noinspection RubyMismatchedReturnType
    attr
  end

  # normalize_file
  #
  # @param [Hash, String, *] data
  #
  # @return [Hash, nil]
  #
  def normalize_file(data, **)
    return unless data.present?
    hash = json_parse(data, log: false) and return hash
    return unless data.is_a?(String)
    data.start_with?(/https?:/i) ? { url: data } : { name: data }
  end

  # normalize_single
  #
  # @param [*]     v
  # @param [Class] type
  # @param [Hash]  opt                Passed to normalization method.
  #
  # @return [*]
  #
  def normalize_single(v, type, **opt)
    case
      when type == 'json'     then normalize_json(v, **opt)
      when type == 'date'     then normalize_date(v, **opt)
      when type == 'datetime' then normalize_datetime(v, **opt)
      when type == 'number'   then normalize_number(v, **opt)
      when type == TrueFalse  then normalize_bool(v, **opt)
      when type.is_a?(Class)  then normalize_enum(v, type, **opt)
      else                         normalize_text(v, **opt)
    end
  end

  # normalize_bool
  #
  # @param [BoolType, String, *] v
  # @param [Boolean]             invalid  Allow invalid values to be imported.
  #
  # @return [true, false, nil]
  #
  def normalize_bool(v, invalid: true, **)
    true?(v) || (false if invalid || false?(v))
  end

  # normalize_number
  #
  # @param [String, Numeric, *] v
  # @param [Boolean]            invalid   Allow invalid values to be imported.
  #
  # @return [Numeric, nil]
  #
  def normalize_number(v, invalid: true, **)
    v = v.to_i if v.is_a?(String)
    # noinspection RubyMismatchedReturnType
    v if invalid || v.is_a?(Numeric)
  end

  # normalize_date
  #
  # @param [Date, String, Numeric, *] v
  #
  # @return [Date, String, nil]
  #
  def normalize_date(v, **)
    v = v.to_s if v.is_a?(Numeric)
    v.is_a?(String) ? (v.to_date rescue v) : v.try(:to_date)
  end

  # normalize_datetime
  #
  # @param [Date, String, Numeric, *] v
  #
  # @return [DateTime, String, nil]
  #
  def normalize_datetime(v, **)
    v = v.to_s if v.is_a?(Numeric)
    v.is_a?(String) ? (v.to_datetime rescue v) : v.try(:to_datetime)
  end

  # normalize_enum
  #
  # @param [Array, String, Symbol, *] v
  # @param [Class]                    type  EnumType subclass
  # @param [Hash]                     opt   Passed to #cast method.
  #
  # @return [Array, String, nil]
  #
  def normalize_enum(v, type, **opt)
    if v.is_a?(Array)
      v.map { |e| normalize_enum(type, e, **opt) }.compact
    else
      type.cast(v, **opt)&.to_s
    end
  end

  # normalize_json
  #
  # @param [Array<Hash,String>, Hash, String, *] v
  #
  # @return [Array<Hash>, Hash, nil]
  #
  def normalize_json(v, **)
    v.is_a?(Array) ? v.flat_map { |h| json_parse(h) }.compact : json_parse(v)
  end

  # normalize_text
  #
  # @param [Array, String, Symbol, *] v
  #
  # @return [String, *]
  #
  def normalize_text(v, **)
    # noinspection RubyMismatchedReturnType
    case v
      when Array  then v.compact.map { |e| normalize_text(e) }.join(LINE_JOIN)
      when Symbol then v.to_s.strip
      when String then v.strip
      else Log.warn { "#{__method__}: type #{v.class} unexpected" } or v
    end
  end

  # normalize_copyright
  #
  # @param [Date, String, Numeric, *] v
  #
  # @return [String, nil]
  #
  def normalize_copyright(v, **)
    v = normalize_date(v)
    v = v.year.to_s if v.is_a?(Date)
    # noinspection RubyMismatchedReturnType
    v if v.is_a?(String)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
