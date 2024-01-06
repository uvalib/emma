# app/models/record/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods relating to record field assignment.
#
module Record::Assignable

  extend ActiveSupport::Concern

  include Record
  include Record::Identification

  include SqlMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveRecord::Core
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Called to prepare values to be used for assignment to record attributes.
  #
  # The return is record field values along with :attr_opt holding all options
  # passed into the method either through *opt* or through *attr* if it is a
  # Hash.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash]                                           opt
  #
  # @option opt [ApplicationRecord]            :from        A record used to provide initial field values.
  # @option opt [User, String, Integer]        :user        Transformed into a :user_id value.
  # @option opt [Symbol, Array<Symbol>]        :force       Allow these fields unconditionally.
  # @option opt [Symbol, Array<Symbol>]        :except      Ignore these fields (default: []).
  # @option opt [Symbol, Array<Symbol>, false] :only        Not limited if *false* (default: `#field_name`).
  # @option opt [Boolean]                      :compact     If *false*, allow blanks (default: *true*).
  # @option opt [Boolean]                      :key_norm    If *true*, transform provided keys to the real column name.
  # @option opt [Boolean]                      :normalized  If *attr* already processed by #normalize_attributes.
  # @option opt [Hash]                         :attr_opt    A hash containing any of the above values.
  #
  # @raise [RuntimeError]             If the type of *attr* is invalid.
  #
  # @return [Hash{Symbol=>*}]
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def normalize_attributes(attr, **opt)
    opt  = opt[:attr_opt].merge(opt.except(:attr_opt)) if opt[:attr_opt]
    meth = opt[:meth] || __method__

    case attr
      when ApplicationRecord
        unless attr.is_a?(record_class)
          Log.warn { "#{record_class}: assigning from a #{attr.class} record" }
        end
        attr = attr.fields.except!(*ignored_keys)
      when Hash
        if (attr_opt = attr[:attr_opt]).is_a?(Hash)
          opt.reverse_merge!(attr_opt)
          return attr.merge(attr_opt: opt) if attr_opt[:normalized]
        end
        attr = attr.except(:attr_opt)
      when nil
        attr = {}
      else
        attr = attr.params      if attr.respond_to?(:params)
        attr = attr.to_unsafe_h if attr.respond_to?(:to_unsafe_h)
        raise "#{attr.class}: unexpected" unless attr.is_a?(Hash)
    end

    from    = opt[:from]
    from  &&= normalize_attributes(from, except: ignored_keys)
    user    = from&.extract!(:user, :user_id)&.compact&.values&.first
    user    = attr.extract!(:user, :user_id).compact.values.first || user
    user    = opt.extract!(:user, :user_id).compact.values.first || user
    force   = Array.wrap(opt[:force])
    excp    = Array.wrap(opt[:except]) - force
    only    = !false?(opt[:only]) && Array.wrap(opt[:only] || allowed_keys)
    compact = !false?(opt[:compact])
    options = [opt[:options], from&.delete(:options)].compact.first

    opt.merge!(options: options) if options.present?
    attr.reverse_merge!(from)    if from.present?

    attr.transform_keys! { |k| k.to_s.delete_suffix('[]').to_sym }
    attr.transform_keys! { |k| normalize_key(k) } if true?(opt[:key_norm])

    attr.merge!(user_id: user)   if (user &&= User.id_value(user))
    attr.slice!(*(only + force)) if only.present?
    attr.except!(*excp)          if excp.present?

    attr.select! do |k, v|
      error   = ("blank key for #{v.inspect}"      if k.blank?)
      error ||= ("ignoring non-field #{k.inspect}" unless database_columns[k])
      error.blank? or Log.warn("#{meth}: #{error}")
    end

    attr = normalize_fields(attr, **opt)
    default_attributes!(attr)
    reject_blanks!(attr) if compact
    attr.merge!(attr_opt: opt.merge!(normalized: true))
  end

  # Include defaults where values were not specified.
  #
  # @param [Hash] attr
  #
  # @return [Hash]                    The *attr* argument, possibly modified.
  #
  def default_attributes!(attr)
    attr
  end

  # The fields that will be accepted by #normalize_attributes.
  #
  # @return [Array<Symbol>]
  #
  def allowed_keys
    field_names.excluding(id_column)
  end

  # The fields that will be ignored by #normalize_attributes from a source
  # passed in via the :from parameter.
  #
  # @return [Array<Symbol>]
  #
  def ignored_keys
    [id_column, :created_at, :updated_at]
  end

  # Return with the key name for the given value.
  #
  # @param [String, Symbol] key
  #
  # @return [Symbol]
  #
  def normalize_key(key)
    key_mapping[EnumType.comparable(key)] || key.to_sym
  end

  # A mapping of key comparison value to actual database column name.
  #
  # @return [Hash{String=>Symbol}]
  #
  def key_mapping
    # noinspection RubyMismatchedReturnType
    EnumType.comparable_map(database_columns.keys)
  end

  # Called by #normalize_attributes after key names have been normalized and
  # attributes have been filtered.
  #
  # @param [Hash] attr
  # @param [Hash] opt
  #
  # @option opt [Boolean]   :invalid  Allow invalid values.
  # @option opt [Symbol]    :meth     Caller (for diagnostics).
  # @option opt [Hash, nil] :errors   Accumulator for errors.
  #
  # @return [Hash]                    A possibly-modified copy of *attr*.
  #
  def normalize_fields(attr, **opt)
    meth = opt[:meth]   || __method__
    err  = opt[:errors] || {}
    lax  = !opt[:invalid].is_a?(FalseClass)
    col  = database_columns
    fld  = database_fields

    attr.map { |k, v|
      next          unless (k &&= k.to_sym).present?
      next [k, nil] unless v.present? || v.is_a?(FalseClass)

      k_alt =
        %w[_id].map do |suffix|
          k.to_s.delete_suffix!(suffix)&.to_sym || "#{k}#{suffix}".to_sym
        end
      array = col.slice(k, *k_alt).values.first&.array
      field = fld.slice(k, *k_alt).values.first || {}
      type  = field[:type] || 'text'

      if array || field[:array] || (type == 'textarea')
        case v
          when Array  then v = v.dup
          when Symbol then v = v.to_s
          when String then v = v.strip.split(LINE_SPLIT)
          else             Log.warn "#{meth}: #{k}: type #{v.class} unexpected"
        end
        v = Array.wrap(v).map! { |item| normalize_field(k, item, type, err) }
        v.compact!
        v.uniq! if type.is_a?(Class)
        v = v.join(LINE_JOIN) unless array

      elsif (v_normal = normalize_field(k, v, type, err)).nil?
        type = [v.class.to_s]
        type << 'skipped' unless lax
        type = type.join(': ')
        Log.warn("#{meth}: #{k}: unexpected #{type}: #{v.inspect}")
        next unless lax

      else
        v = v_normal
      end

      [k, v]
    }.compact.to_h
  end

  # Normalize a specific field value.
  #
  # @param [Symbol]        key
  # @param [*]             value
  # @param [String, Class] type
  # @param [Hash, nil]     errors
  #
  # @return [*]
  #
  def normalize_field(key, value, type, errors = nil)
    result =
      case key
        when :dcterms_dateCopyright then normalize_copyright(value)
        when :file_data             then normalize_file(value).presence
        else                             normalize_single(value, type)
      end
    add_field_error!(key, value, errors) if errors && is_invalid?(result, type)
    case result
      when FalseClass        then result
      when ScalarType        then result.to_s.presence
      when ApplicationRecord then key.end_with?('_id') ? result.id : result
      else                        result.presence
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Pattern by which string attribute values are split into arrays.
  #
  # @type [String,Regexp]
  #
  LINE_SPLIT = /[;\n]+/

  # String by which array attribute values are combined into strings.
  #
  # @type [String,RegExp]
  #
  LINE_JOIN = ";\n"

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
      when true, false  then !v.is_a?(TrueFalse)
      when 'json'       then !v.is_a?(Hash)
      when 'date'       then !v.is_a?(Date)
      when 'datetime'   then !v.is_a?(DateTime)
      when 'number'     then !v.is_a?(Numeric)
      else                   v.respond_to?(:valid?) ? !v.valid? : v.nil?
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
    case type
      when Class        then normalize_class(v, type, **opt)
      when true, false  then normalize_bool(v)
      when 'json'       then normalize_json(v)
      when 'date'       then normalize_date(v)
      when 'datetime'   then normalize_datetime(v)
      when 'number'     then normalize_number(v)
      else                   normalize_text(v)
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

  # normalize_class
  #
  # @param [*]     v
  # @param [Class] type               EnumType or ApplicationRecord subclass
  # @param [Hash]  opt                Passed to EnumType#cast method.
  #
  # @return [ApplicationRecord, EnumType, nil]
  #
  def normalize_class(v, type, **opt)
    # noinspection RubyMismatchedReturnType
    if type < ApplicationRecord
      normalize_record(v, type, **opt) || v
    elsif type < EnumType
      normalize_enum(v, type, **opt)
    else
      Log.warn("#{__method__}: #{type} unexpected")
    end
  end

  # normalize_record
  #
  # @param [*]     v
  # @param [Class] type               EnumType subclass
  #
  # @return [ApplicationRecord, nil]
  #
  def normalize_record(v, type, **)
    type.instance_for(v)
  end

  # normalize_enum
  #
  # @param [*]     v
  # @param [Class] type               EnumType subclass
  # @param [Hash]  opt                Passed to #cast method.
  #
  # @return [EnumType, nil]
  #
  def normalize_enum(v, type, **opt)
    type.cast(v, invalid: true, **opt)
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
      when Array  then v.compact.map! { |s| normalize_text(s) }.join(LINE_JOIN)
      when String then v.strip
      when Symbol then v.to_s
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::Assignable
  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    include Record::Assignable

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::AttributeAssignment
      include Record::Debugging::InstanceMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Model/controller options passed in through the constructor.
    #
    # @return [::Options]
    #
    attr_reader :model_options

    # set_model_options
    #
    # @param [::Options, Hash, nil] options
    #
    # @return [::Options]
    #
    def set_model_options(options)
      options = options[:options] if options.is_a?(Hash)
      # noinspection RubyMismatchedReturnType, RubyMismatchedVariableType
      if options.is_a?(::Options)
        @model_options = options.dup
      else
        @model_options = ::Options.new
      end
    end

    # =========================================================================
    # :section: ActiveRecord overrides
    # =========================================================================

    public

    # Create a new instance.
    #
    # @param [Model, Hash, nil] attr
    #
    # @return [void]
    #
    # @note - for dev traceability
    #
    def initialize(attr = nil)
      super
    end

    # Update database fields, including the structured contents of JSON fields.
    #
    # @param [Model, Hash, ActionController::Parameters, nil] attr
    #
    # @return [void]
    #
    # @see #normalize_attributes
    # @see ActiveModel::AttributeAssignment#assign_attributes
    #
    def assign_attributes(attr)
      attr = normalize_attributes(attr)
      opt  = attr.delete(:attr_opt) || {}
      set_model_options(opt)
      super
    rescue => err # TODO: testing - remove?
      Log.warn { "#{record_name}.#{__method__}: #{err.class}: #{err.message}" }
      raise err
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

    include InstanceMethods

  end

end

__loading_end(__FILE__)
