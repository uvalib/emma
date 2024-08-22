# app/models/concerns/sort_order.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class SortOrder < Hash

  # The URL query parameter for the sort order.
  #
  # @type [Symbol]
  #
  URL_PARAM = :sort

  # Field name URL sort parameter names with this suffix are interpreted as
  # a descending sort on the database column indicated by the root name.
  # (E.g., "last_name_rev" will result in `{ last_name: :desc }`.)
  #
  # @type [String]
  #
  REVERSE_SUFFIX = '_rev'

  # Sort directions.
  #
  # @type [Array<Symbol>]
  #
  DIRECTIONS = %i[asc desc].freeze

  # Default sort direction.
  #
  # @type [Symbol]
  #
  DEF_DIRECTION = :asc

  # Field name URL parameters which need "_id" to be used as database column
  # names. (E.g., "?sort=user" will order on "user_id".)
  #
  # @type [Array<String>]
  #
  ID_FIELD = %w[
    active_job
    manifest
    org
    submission
    user
  ].freeze

  # Field name URL parameters which need "_at" to be used as database column
  # names. (E.g., "?sort=updated" will order on "updated_at".)
  #
  # @type [Array<String>]
  #
  AT_FIELD = %w[
    created
    updated
  ].freeze

  # Field name URL parameters which need "_count" to be used as database column
  # names. (E.g., "?sort=upload" will order on "upload_count".)
  #
  # @type [Array<String>]
  #
  COUNT_FIELD = %w[
    upload
    manifest
  ].freeze

  # Indicate whether validity should be checked when emitting a result.
  #
  # @type [Boolean]
  #
  VALIDATE = sanity_check?

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [String, nil]
  attr_reader :raw_sql # Raw SQL only

  # Initialize a new instance.
  #
  # @param [any, nil] value           SortOrder, Hash, Array
  # @param [Hash]     opt             Passed to #parse.
  #
  def initialize(value = nil, **opt)
    # noinspection RubyMismatchedArgumentType
    case (value &&= parse(value, meth: 'SortOrder', fatal: true, **opt))
      when String then @raw_sql = value
      when Hash   then update(value)
    end
  end

  # ===========================================================================
  # :section: Hash overrides
  # ===========================================================================

  public

  # Indicate whether the instance does not represent a sort of any kind (i.e.,
  # neither a raw SQL sort nor order/direction pairs).
  #
  def empty?
    raw_sql.blank? && super
  end

  # Return this sort value as a URL parameter.
  #
  # @param [Symbol] key
  #
  # @return [String]
  #
  def to_param(key = URL_PARAM)
    [key, param_value].join('=')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the instance represents a raw SQL sort and does not
  # include order/direction pairs.
  #
  def sql_only?
    raw_sql.present?
  end

  # Return the value which can be used as an ActiveRecord #order argument.
  #
  # @return [Hash{Symbol=>Symbol}, String, nil]
  #
  def sql_order
    validate
    raw_sql.presence || to_h.presence
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the order/direction pairs as a comma-separated string.
  #
  # @param [String] separator
  #
  # @return [String]
  #
  def param_value(separator: ',')
    validate
    if sql_only?
      url_escape(raw_sql)
    else
      map { |k, v| (v == :desc) ? "#{k}#{REVERSE_SUFFIX}" : k }.join(separator)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Raise an exception if the instance has not been constructed properly.
  #
  # @return [nil]
  #
  def validate
    return unless VALIDATE
    err = []
    val = values.presence
    if sql_only?
      err << 'raw_sql and order/direction pairs are mutually exclusive' if val
    elsif (val &&= val.excluding(*DIRECTIONS).presence)
      err += val.uniq.map { |v| "#{v}: invalid direction" }
    end
    fail('SortOrder: %s' % err.join('; ')) if err.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance from *item* if it is not already an instance.
  #
  # @param [any, nil] item            Expected SortOrder or Hash.
  #
  # @return [SortOrder]
  #
  def self.wrap(item, **opt)
    # noinspection RubyMismatchedReturnType
    item.is_a?(self) ? item : new(item, **opt)
  end

  delegate :wrap, to: :class

  # Interpret a value as a raw SQL sort or order/direction pair(s).
  #
  # @param [any, nil]            value  SortOrder, Hash
  # @param [Symbol, String, nil] dir
  # @param [Symbol, String, nil] col
  # @param [Symbol, String, nil] meth
  # @param [Boolean, nil]        fatal
  # @param [Boolean, nil]        record
  #
  # @return [Hash{Symbol=>Symbol}]
  # @return [String]                  If *value* is a SQL expression.
  # @return [nil]                     If *value* is *nil*, *false*, or empty.
  #
  def self.parse(
    value,
    dir:    nil,
    col:    nil,
    meth:   nil,
    fatal:  nil,
    record: nil,
    **
  )

    # Handle Hash and raw_sql SQL cases immediately.
    case value
      when SortOrder then return value
      when String    then return value if value.match?(%r{[()*/+-]})
      else                return if value.blank?
    end

    # Validate options.
    e_opt = { fatal: fatal, meth: meth || __method__}
    col &&= col.to_s.strip.downcase
    if dir && !DIRECTIONS.include?(dir)
      val = DIRECTIONS.find { |d| dir.to_s.match?(/^#{d}/i) }
      error("invalid sort direction: #{dir.inspect}", **e_opt) unless val
      dir = val
    end
    dir ||= DEF_DIRECTION

    # Prepare one or more sort field names.
    case value
      when Hash      then value = value.to_a
      when String    then value = value.split(/\s*,\s*/)
      when Array     then # elements of String, Symbol, and/or sort/order pairs
      when Symbol    then # wrapped below
      when TrueClass then # wrapped below
      else error(**e_opt) { "invalid #{value.class}: #{value.inspect}" }
    end

    # Translate sort fields or name/value pairs into order/direction pairs.
    Array.wrap(value).map { |key|
      err = nil
      if key.is_a?(Array)
        key, val = key
        field    = key # Original key for error reporting.
        key      = key.to_s.strip.downcase
        next if key.blank?
      else
        field    = key # Original key for error reporting.
        key, val = key.to_s.strip.downcase, nil
        key, val = key.split('=', 2).map(&:strip) if key.include?('=')
        case
          when key == ''                then next
          when key == 'false'           then next
          when key == 'true'            then key = col
          when key == 'desc'            then key, val = [col, :desc]
          when key == 'asc'             then key, val = [col, :asc]
          when key.sub!(/\s+desc$/, '') then val = :desc
          when key.sub!(/\s+asc$/, '')  then val = :asc
        end
        err = 'requires missing :col param' if key.blank?
      end

      # Validate the sort order key and sort direction value.
      case
        when false?(val)              then next
        when true?(val) || val.blank? then val = dir
        when val.is_a?(String)        then val = val.to_sym
      end
      unless DIRECTIONS.include?(val)
        err, val = "invalid sort value: #{val.inspect}", DEF_DIRECTION
      end
      next error(err, field: field, **e_opt) if err

      # If the key ended in "_rev" then normalize it and reverse direction.
      rev = key.delete_suffix!(REVERSE_SUFFIX).present?
      val = (val == :desc) ? :asc : :desc if rev

      # Restore short-hand URL parameters to actual field names.
      if record
        case key
          when *ID_FIELD    then key = "#{key}_id"
          when *AT_FIELD    then key = "#{key}_at"
          when *COUNT_FIELD then key = "#{key}_count"
        end
      end

      [key.to_sym, val.to_sym]
    }.compact.to_h.presence
  end

  delegate :parse, to: :class

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Report an error or raise an exception if *fatal* is *true*.
  #
  # @param [any, nil]     msg
  # @param [any, nil]     field
  # @param [Boolean, nil] fatal
  # @param [Symbol, nil]  meth
  #
  # @return [nil]
  #
  def self.error(msg = nil, field: nil, fatal: nil, meth: nil, **)
    msg = Array.wrap(msg || yield).join('; ')
    msg = [meth, field, msg].compact.join(': ')
    # noinspection RubyMismatchedArgumentType
    fatal and raise(msg) or Log.error(msg)
  end

  delegate :error, to: :class

end

__loading_end(__FILE__)
