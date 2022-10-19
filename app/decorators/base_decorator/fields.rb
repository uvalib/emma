# app/decorators/base_decorator/fields.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting manipulation of Model instance fields.
#
module BaseDecorator::Fields

  include Emma::Json

  include BaseDecorator::Links

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field value used to explicitly indicate missing data.
  #
  # @type [String]
  #
  EMPTY_VALUE = EN_DASH

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field/value pairs.
  #
  # @param [Model, Hash, nil] item    Default: `#object`.
  #
  # @return [Hash]
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedReturnType
  #++
  def field_values(item = nil)
    item ||= object
    case item
      when ApplicationRecord
        # Convert :file_data and :emma_data into hashes and move to the end.
        data, pairs = partition_hash(item.fields, :file_data, :emma_data)
        data.each_pair { |k, v| pairs[k] = json_parse(v) }
      when Api::Record
        item.field_names.map { |f| [f.to_s.titleize.to_sym, f] }.to_h
      when Hash
        item
      else
        {}
    end
  end

  # field_pairs
  #
  # @param [Model, Hash, nil]           item        Passed to #field_values.
  # @param [String, Symbol, nil]        action
  # @param [Symbol, Array<Symbol>, nil] field_root  Limits field configuration.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # == Usage Notes
  # If *field_root* is given it is used to transform the field into a path
  # into the configuration.  The only current use is to allow specification of
  # :file_data so that configuration lookup is limited to the hierarchy within
  # the configuration for :file_data.  (This allows [:file_data][:id] to be
  # associated with the proper field configuration.)
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def field_pairs(item = nil, action: nil, field_root: nil, **)
    field_values(item).map { |k, v|
      field, value, config = k, v, nil
      if v.is_a?(Symbol)
        field = v
      elsif k.is_a?(Symbol) && v.is_a?(Hash)
        config = v
        value  = config[:value]
      end

      if field_root
        field    = [field_root, field]
        config   = field_configuration(field, action)
      elsif field.is_a?(String)
        config ||= field_configuration_for_label(field, action)
        field    = config[:field] if config&.dig(:field)&.is_a?(Symbol)
      else
        config ||= field_configuration(field, action)
      end

      prop = field_properties(field, config)
      prop[:field]   = field.join('_').to_sym if field.is_a?(Array)
      prop[:field] ||= (field if field.is_a?(Symbol))
      prop[:label] ||= (k     if k.is_a?(String))
      prop[:value]   = value

      [field, prop]
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Field type indicators mapped on to related class(es).
  #
  # @type [Hash{Symbol=>Array<Class>}]
  #
  RENDER_FIELD_TYPE_TABLE = {
    check:    [Boolean, TrueClass, FalseClass],
    date:     [IsoDate, IsoDay, Date],
    datetime: [DateTime, ActiveSupport::TimeWithZone],
    number:   [Integer, BigDecimal],
    time:     [Time],
    year:     [IsoYear],
  }.transform_values! { |types|
    types.flat_map { |type|
      # noinspection RubyMismatchedArgumentType
      [type].tap do |related|
        name = (type == BigDecimal) ? 'Decimal' : type
        related << safe_const_get("Axiom::Types::#{name}")
        related << safe_const_get("ActiveModel::Type::#{name}")
      end
    }.compact
  }.deep_freeze

  # Mapping of actual type to the appropriate field type indicator.
  #
  # @type [Hash{Class=>Symbol}]
  #
  RENDER_FIELD_TYPE =
    RENDER_FIELD_TYPE_TABLE.flat_map { |field, types|
      types.map { |type| [type, field] }
    }.sort_by { |pair| pair.first.to_s }.to_h.freeze

  # Convert certain field types.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  REPLACE_FIELD_TYPE = {
=begin
    year: :text, # Currently treating :year as plain text.
    date: :text, # Currently treating :date as plain text.
    time: :text, # Currently treating :time as plain text.
=end
  }.freeze

  # render_field_item
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt               Passed to render method except for:
  #
  # @option opt [String] :base
  # @option opt [String] :name
  # @option opt [Symbol] :type
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_item(name, value, **opt)
    normalize_attributes!(opt)
    local = extract_hash!(opt, :base, :name, :type)
    field = opt[:'data-field']
    name  = local[:name] || name || local[:base] || field
    value = Array.wrap(value).compact_blank
    type  = local[:type] || field_configuration(field)[:type]
    type  = type.to_sym                          if type.is_a?(String)
    type  = RENDER_FIELD_TYPE[value.first.class] unless type.is_a?(Symbol)
    type  = REPLACE_FIELD_TYPE[type] || type || :text
    value =
      case type
        when :check    then true?(value.first)
        when :number   then value.first.to_s.remove(/[^\d]/)
        when :textarea then value.join("\n").split(/[ \t]*\n[ \t]*/).join("\n")
        when :datetime then format_datetime(value.first)
        when :date     then value.first.to_s
        when :time     then value.first.to_s.sub(/^([^ ]+).*$/, '\1')
        when :year     then value.first.to_s.sub(/\s.*$/, '')
        else value.map { |v| v.to_s.strip.presence }.compact.join(' | ')
      end
    case type
      when :check    then render_check_box(name, value, **opt)
      when :email    then h.email_field_tag(name, value, opt)
      when :number   then h.number_field_tag(name, value, opt.merge(min: 0))
      when :password then h.password_field_tag(name, value, opt)
      when :textarea then h.text_area_tag(name, value, opt)
      when :datetime then h.datetime_field_tag(name, value, opt)
      when :date     then h.date_field_tag(name, value, opt)
      when :time     then h.time_field_tag(name, value, opt)
      when :year     then h.text_field_tag(name, value, opt)
      else                h.text_field_tag(name, value, opt)
    end
  end

  # Local options for #render_check_box.
  #
  # @type [Array<Symbol>]
  #
  CHECK_OPTIONS =
    %i[id checked disabled readonly required data-required label].freeze

  # render_check_box
  #
  # @param [String] name
  # @param [Any]    value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_check_box(name, value, **opt)
    css      = '.checkbox.single'
    html_opt = remainder_hash!(opt, *CHECK_OPTIONS)
    normalize_attributes!(opt)

    # Checkbox control.
    checked  = opt.delete(:checked)
    checkbox = h.check_box_tag(name, value, checked, opt)

    # Label for checkbox.
    lbl_opt  = { for: opt[:id] }.compact
    label    = opt.delete(:label) || value
    label    = h.label_tag(name, label, lbl_opt)

    # Checkbox/label combination.
    prepend_css!(html_opt, css)
    html_div(html_opt) do
      checkbox << label
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # This is a "hook" to allow customization by SearchDecorator.
  #
  # @param [Symbol]    field
  # @param [Hash, nil] config
  #
  # @return [Hash]
  #
  def field_properties(field, config = nil)
    field_configuration(field).merge(config || {})
  end

  # Indicate whether the value is a valid range type.
  #
  # @param [*]       range
  # @param [Boolean] exception        If *true*, raise an exception if *false*.
  #
  # @raise [RuntimeError]             If not valid and *exception* is *true*.
  #
  def valid_range?(range, exception: false)
    valid = range.is_a?(Class) && (range < EnumType)
    exception &&= !valid
    raise "range: #{range.inspect}: not a subclass of EnumType" if exception
    valid
  end

  # Translate attributes.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The potentially-modified *opt* hash.
  #
  # == Implementation Notes
  # Disabled input fields are given the :readonly attribute because the
  # :disabled attribute prevents those fields from being included in the data
  # sent with the form submission.
  #
  def normalize_attributes!(opt)
    field    = opt.delete(:field)    || opt[:'data-field']
    required = opt.delete(:required) || opt[:'data-required']
    readonly = opt.delete(:disabled) || opt[:readonly]

    opt[:'data-field']    = field if field
    opt[:'data-required'] = true  if required
    opt[:readonly]        = true  if readonly

    append_css!(opt, 'required')  if required
    append_css!(opt, 'disabled')  if readonly
    opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The defined levels for rendering an item hierarchically.
  #
  # @param [Hash] opt
  #
  # @return [Hash{Symbol=>Array<Symbol,Integer>}]
  #
  def field_levels(**opt)
    {} # May be overridden by the subclass.
  end

  # Return with the CSS classes associated with the items field scope(s).
  #
  # @param [Array, Symbol, String, nil] value
  #
  # @return [Array<String>]
  #
  #--
  # == Variations
  #++
  #
  # @overload field_scopes(single)
  #   Interpret the argument as a field name used to lookup the scope values.
  #   @param [Symbol, String, nil] single
  #   @return [Array<String>]
  #
  # @overload field_scopes(array)
  #   Extract the scopes from *array*.
  #   @param [Array<Symbol>]       array
  #   @return [Array<String>]
  #
  def field_scopes(value)
    levels = value.is_a?(Array) ? value : field_levels[value&.to_sym]
    levels = levels&.select { |s| s.is_a?(Symbol) || s.is_a?(String) } || []
    levels.map! { |s| "scope-#{s}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # EMMA data field prefixes with trailing underscore for #model_html_id.
  #
  # @type [Array<String>]
  #
  FIELD_PREFIX =
    DataHelper::EMMA_DATA_FIELDS.map { |field|
      field.to_s.sub(/_.*$/, '_')
    }.uniq.deep_freeze

  # Suffixes indicating field names to be preserved in #model_html_id.
  #
  # @type [Array<String>]
  #
  RESERVED_SUFFIX = %w(_data _date).freeze

  # Create a base for .field-* and .value-* classes.
  #
  # @param [Symbol, String, nil] base   Default: 'None'.
  #
  # @return [String]
  #
  def model_html_id(base)
    name = base.to_s.strip
    unless name.end_with?(*RESERVED_SUFFIX)
      # noinspection RubyMismatchedReturnType
      FIELD_PREFIX.find { |prefix| name.delete_prefix!(prefix) }
    end
    name = 'None' if name.blank?
    html_id(name, camelize: true)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # format_datetime
  #
  # @param [*] value
  #
  # @return [String, nil]
  #
  def format_datetime(value)
    value.try(:to_datetime)&.strftime('%Y-%m-%dT%H:%M:%S')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Match a major section title in a table-of-contents listing.
  #
  # @type [Regexp]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  SECTION_TITLE_RE = /^(PART|[CDILMVX]+\.?|[cdilmvx]+\.|\d+\.|v\.) +(.*)/

  # For use with String#scan to step through quote/attribute pairs.
  #
  # @type [Regexp]
  #
  BLURB_RE = /([^\n]*?[[:punct:]]) *-- *([^\n]+?\.\s+|[^\n]+\s*)/

  # Reformat descriptions which are structured in a way that one would find
  # in MARC metadata.
  #
  # @param [String] text
  #
  # @return [Array<String>]
  #
  # == Usage Notes
  # Descriptions like this don't currently seem to appear very often in search
  # results.  Even for those that do, they may not adhere to the expected
  # layout of information, and this method may not be that beneficial in those
  # cases.
  #
  def format_description(text)
    # Look for signs of structure, otherwise just treat as unstructured.
    case text
      when /"";/                     then double_quotes_to_sections(text)
      when /\.--v\. */               then double_dash_to_sections(text)
      when /; *PART */i              then # Seen in some IA records.
      when /:;/                      then # Observed in one unusual case.
      when /[[:punct:]] *--.* +-- +/ then # Blurbs/quotes with attribution.
      when / +-- +.* +-- +/          then # Table-of-contents title list.
      when /(;[^;]+){4,}/            then # Many sections indicated.
      else                                return format_multiline(text)
    end
    q_section = nil
    text.split(/ *; */).flat_map { |part|
      next if (part = part.strip).blank?
      case part
        when /^""(.*)""$/
          # == Rare type of table-of-contents listing entry
          line = $1.to_s
          if line.match(SECTION_TITLE_RE)
            gap       = ("\n" unless q_section)
            q_section = $1.to_s
            [gap, "#{q_section} #{$2}", "\n"].compact
          else
            q_section = nil
            line.match?(/^\d+ +/) ? line : "#{BLACK_CIRCLE}#{EN_SPACE}#{line}"
          end

        when / +-- +.* +-- +/
          # === Table-of-contents listing
          section = nil
          part.split(/ +-- +/).flat_map { |line|
            if line.match(SECTION_TITLE_RE)
              gap     = ("\n" unless section)
              section = $1.to_s.delete_suffix('.')
              [gap, "#{section}. #{$2}", "\n"].compact
            else
              section = nil
              "#{BLACK_CIRCLE}#{EN_SPACE}#{line}"
            end
          }.tap { |toc| toc << "\n" unless toc.last == "\n" }

        when /[[:punct:]] *--/
          # === Blurbs/quotes with attribution
          part.scan(BLURB_RE).flat_map do |paragraph, attribution|
            attribution.remove!(/[.\s]+$/)
            ["#{paragraph} #{EM_DASH}#{attribution}.", "\n"]
          end

        when /^v[^.]*\. *\d/
          # === Apparent table-of-contents volume title
          [part]

        else
          # === Plain text section
          part = "#{part}." unless part.match?(/[[:punct:]]$/)
          [part, "\n"]
      end
    }.compact.map { |line|
      line.gsub(/---/, EM_DASH).gsub(/--/,  EN_DASH)
    }
  end

  # Seen in some IA records.
  #
  # @param [String]
  #
  # @return [String]
  #
  def double_quotes_to_sections(text)
    text.to_s.gsub(/"" ""|""""/, '""; ""')
  end

  # Seen in some IA records.
  #
  # @param [String]
  #
  # @return [String]
  #
  def double_dash_to_sections(text)
    text.to_s.dup.tap do |result|
      result.sub!( /(\S) +(v[^.\s]*\.) */,     '\1 -- \2 ')
      result.gsub!(/(\S) *-- *(v[^.\s]*\.) */, '\1; \2 ')
    end
  end

  # Transform a string with newlines/semicolons into an array of lines.
  #
  # @param [String] text
  #
  # @return [Array<String>]
  #
  def format_multiline(text)
    Array.wrap(text).flat_map { |s| s.to_s.split(/ *[;\n] */) }.compact_blank!
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  VALID_LANGUAGE   = 'Provided value: %s' # TODO: I18n
  INVALID_LANGUAGE = 'The underlying data contains this value ' \
                     'instead of a valid ISO 639 language code.'

  # Wrap invalid language values in a *span*.
  #
  # @param [Any]     value            Value to check.
  # @param [Boolean] code             If *true* display the ISO 639 code.
  #
  # @return [ActiveSupport::SafeBuffer, String, Array]
  #
  #--
  # == Variations
  #++
  #
  # @overload mark_invalid_languages(value, code: false)
  #   @param [String]        value
  #   @param [Boolean]       code
  #   @return [String, ActiveSupport::SafeBuffer, nil]
  #
  # @overload mark_invalid_languages(array, code: false)
  #   @param [Array<String>] array
  #   @param [Boolean]       code
  #   @return [Array<String, ActiveSupport::SafeBuffer>]
  #
  def mark_invalid_languages(value, code: false)
    if value.is_a?(Array)
      return value.map { |v| send(__method__, v, code: code) }
    end
    lang = IsoLanguage.find(value)
    return value if code ? (value == lang&.alpha3) : lang
    if lang
      opt   = { title: (VALID_LANGUAGE % value.inspect) }
      value = code ? lang.alpha3 : lang.english_name
    else
      opt   = { title: (INVALID_LANGUAGE % value.inspect), class: 'invalid' }
    end
    html_span(value, opt)
  end

  # Wrap invalid identifier values in a *span*.
  #
  # @param [Any] value                Value to check.
  #
  # @return [ActiveSupport::SafeBuffer, String, Array]
  #
  #--
  # == Variations
  #++
  #
  # @overload mark_invalid_identifiers(value)
  #   @param [String]        value
  #   @return [String, ActiveSupport::SafeBuffer]
  #
  # @overload mark_invalid_identifiers(array)
  #   @param [Array<String>] array
  #   @return [Array<String, ActiveSupport::SafeBuffer>]
  #
  def mark_invalid_identifiers(value)
    return value.map { |v| send(__method__, v) } if value.is_a?(Array)
    type, id_part = value.split(':', 2)
    if id_part.nil? # No type prefix.
      value
    elsif (identifier = PublicationIdentifier.create(id_part, type))&.valid?
      identifier.to_s
    else
      tip = "This is not a valid #{type.upcase} identifier." # TODO: I18n
      html_span(value, class: 'invalid', title: tip)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
