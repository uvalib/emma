# app/models/manifest_item/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Assignable

  include ManifestItem::Config
  include ManifestItem::StatusMethods
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
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash, nil]                                      opt
  #
  # @option opt [Boolean] :invalid      Allow invalid values.
  # @option opt [Symbol]  :meth         Caller (for diagnostics).
  # @option opt [Boolean] :re_validate  Caller will validate so skip that here.
  #
  # @return [Hash{Symbol=>*}]
  #
  def normalize_attributes(attr, opt = nil)
    opt  = opt ? (opt[:attr_opt]&.dup || {}).merge!(opt.except(:attr_opt)) : {}
    opt  = attr[:attr_opt].merge(opt) if attr.is_a?(Hash) && attr[:attr_opt]
    opt.reverse_merge!(compact: false, key_norm: true)
    attr = super(attr, opt)
    opt  = attr.delete(:attr_opt) || {}
    meth = opt[:meth] || __method__
    lax  = !opt[:invalid].is_a?(FalseClass)
    err  = ({} unless opt[:re_validate])
    # noinspection RubyMismatchedArgumentType
    attr = default_attributes(attr)
    attr.map { |k, v|
      next [k, nil] unless v.present? || v.is_a?(FalseClass)

      column = database_columns[k]
      field  = database_fields[k]
      type   = field[:type]
      enum   = type.is_a?(Class) && (type < EnumType)
      v_orig = v

      if column.array || field[:array] || (type == 'textarea')
        case v
          when Array  then v = v.dup
          when Symbol then v = v.to_s
          when String then v = v.strip.split(LINE_SPLIT)
          else             Log.warn "#{meth}: #{k}: type #{v.class} unexpected"
        end
        v = Array.wrap(v)
        v.map! { |element|
          normal = normalize_single(element, type)
          add_field_error!(k, element, err) if err && is_invalid?(normal, type)
          normal = normal.presence unless normal.is_a?(FalseClass)
          normal = normal.to_s     if normal.is_a?(ScalarType)
          normal
        }.compact!
        v.uniq! if enum
        v = v.join(LINE_JOIN) unless column.array
      elsif k == :file_data
        v = normalize_file(v).presence
      elsif k == :dcterms_dateCopyright
        v = normalize_copyright(v)
      else
        v_normal = normalize_single(v, type)
        add_field_error!(k, v, err)  if err && is_invalid?(v_normal, type)
        v_normal = v_normal.presence unless v_normal.is_a?(FalseClass)
        v_normal = v_normal.to_s     if v_normal.is_a?(ScalarType)
        v = v_normal
      end

      if v.nil?
        type = [v_orig.class.to_s]
        type << 'skipped' unless lax
        type = type.join(': ')
        Log.warn("#{meth}: #{k}: unexpected #{type}: #{v_orig.inspect}")
        next unless lax
        v = v_orig
      end

      [k, v]
    }.compact.to_h.tap do |result|
      unless opt[:re_validate]
        result[:field_error] = err
        update_status!(result, **opt.slice(*UPDATE_STATUS_OPTS))
      end
      result[:attr_opt] = opt
    end
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

  protected

  # The phrase indicating a problematic value. # TODO: I18n
  #
  # @type [String]
  #
  INVALID_FIELD = 'illegal value'

  # Indicate whether the value is valid for *type*.
  #
  # @param [*]             v
  # @param [String, Class] type
  #
  def is_invalid?(v, type)
    case type
      when 'json'     then !v.is_a?(Hash)
      when 'date'     then !v.is_a?(Date)
      when 'datetime' then !v.is_a?(DateTime)
      when 'number'   then !v.is_a?(Numeric)
      when TrueFalse  then !v.is_a?(TrueFalse)
      else                 v.respond_to?(:valid?) ? !v.valid? : v.nil?
    end
  end

  # add_field_error!
  #
  # @param [Hash, String, Symbol] field
  # @param [any, nil]             value
  # @param [Hash, nil]            target  Default: `#field_error`.
  #
  # @return [Hash{Symbol=>Hash{String=>String}}]
  #
  def add_field_error!(field, value = nil, target = nil)
    target ||= (self.field_error ||= {})
    errors   = field.is_a?(Hash) ? field : { field.to_sym => value }
    errors.each_pair do |fld, err|
      case err
        when Hash  then err = err.stringify_keys
        when Array then err = err.map { |k| [k.to_s, nil] }.to_h
        else            err = { err.to_s => nil }
      end
      err.each_pair { |k, v| err[k] = INVALID_FIELD if v.nil? }
      if target[fld]
        err.each_pair { |k, v| target[fld][k] = [*target[fld][k], *v].uniq }
      else
        target[fld] = err
      end
    end
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
    attr ||= {}
    return attr if attr[:repository] || ALLOW_NIL_REPOSITORY
    attr.merge(repository: EmmaRepository.default)
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
  # @param [*]            v
  # @param [String,Class] type
  # @param [Hash]         opt         Passed to normalization method.
  #
  # @return [*]
  #
  def normalize_single(v, type, **opt)
    # noinspection RubyMismatchedArgumentType
    case
      when type == 'json'     then normalize_json(v)
      when type == 'date'     then normalize_date(v)
      when type == 'datetime' then normalize_datetime(v)
      when type == 'number'   then normalize_number(v)
      when type == TrueFalse  then normalize_bool(v)
      when type.is_a?(Class)  then normalize_enum(v, type, **opt)
      else                         normalize_text(v)
    end
  end

  # normalize_bool
  #
  # @param [BoolType, String, *] v
  #
  # @return [true, false, nil]
  #
  def normalize_bool(v, **)
    true?(v) || (false if false?(v))
  end

  # normalize_number
  #
  # @param [String, Numeric, *] v
  #
  # @return [Numeric, nil]
  #
  def normalize_number(v, **)
    v = v.to_i if v.is_a?(String)
    # noinspection RubyMismatchedReturnType
    v if v.is_a?(Numeric)
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
  # @return [Array<EnumType>, EnumType, nil]
  #
  def normalize_enum(v, type, **opt)
    if v.is_a?(Array)
      v.map { |e| normalize_enum(type, e, **opt) }.compact
    else
      opt[:invalid]     = true unless opt.key?(:invalid)
      opt[:nil_default] = true unless opt[:invalid]
      type.cast(v, **opt)
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
