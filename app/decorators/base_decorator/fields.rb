# app/decorators/base_decorator/fields.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting manipulation of Model instance fields.
#
module BaseDecorator::Fields

  include BaseDecorator::Common
  include BaseDecorator::Configuration

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Database columns with hierarchical data.
  #
  # @return [Array<Symbol>]
  #
  def compound_fields
    %i[file_data emma_data]
  end

  # emma_data_fields
  #
  # @param [Symbol] field
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def emma_data_fields(field = :emma_data)
    model_database_fields[field]&.select { |_, v| v.is_a?(Hash) } || {}
  end

  # Render the contents of the :emma_data field in the same order of EMMA data
  # fields as defined for search results.
  #
  # @param [String, Hash, nil] value
  # @param [Symbol]            field
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_json_data
  #
  def render_emma_data(value = nil, field: :emma_data, **opt)
    value ||= object.try(field) || object.try(:[], field)
    pairs   = json_parse(value).presence
    pairs &&=
      emma_data_fields(field).map { |fld, cfg|
        value = pairs.delete(cfg[:label]) || pairs.delete(fld)
        [fld, value] unless value.nil?
      }.compact.to_h.merge(pairs)
    opt[:outer] = trace_attrs(opt[:outer])
    render_json_data(pairs, **opt)
  end

  # Render the contents of the :file_data field.
  #
  # @param [String, Hash, nil] value
  # @param [Symbol]            field
  # @param [Hash]              opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_json_data
  #
  def render_file_data(value = nil, field: :file_data, **opt)
    value ||= object.try(field) || object.try(:[], field)
    opt[:outer] = trace_attrs(opt[:outer])
    render_json_data(value, **opt, field_root: field)
  end

  # Render hierarchical data.
  #
  # @param [String, Hash, nil] value
  # @param [Hash, nil]         outer  Options for outer div.
  # @param [String]            css    Characteristic CSS class/selector.
  # @param [Hash]              opt    Passed to #render_field_values
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def render_json_data(value, outer: nil, css: '.data-list', **opt)
    value &&= json_parse(value) unless value.is_a?(Hash)
    outer   = outer&.dup || {}
    prepend_css!(outer, css)
    trace_attrs!(outer)
    html_div(**outer) do
      t_opt = trace_attrs_from(outer)
      if value.present?
        opt[:no_fmt] ||= :dc_description
        root  = opt[:field_root]
        pairs =
          value.map { |k, v|
            if v.is_a?(Hash)
              sub_opt = root ? opt.merge(field_root: [root, k.to_sym]) : opt
              v = render_json_data(v, **sub_opt)
            end
            [k, v]
          }.to_h
        render_field_values(pairs: pairs, **opt, **t_opt)
      else
        render_empty_value(message: EMPTY_VALUE, **t_opt)
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options for #field_value_pairs.
  #
  # @type [Array<Symbol>]
  #
  FIELD_VALUE_PAIRS_OPT = %i[pairs before after].freeze

  # Field/value pairs.
  #
  # @param [Model, Hash, nil]  item     Default: *pairs*.
  # @param [Model, Hash, nil]  pairs    Default: `#object`.
  # @param [Hash, nil]         before   Additional leading label/value pairs.
  # @param [Hash, nil]         after    Additional trailing label/value pairs.
  # @param [ActionConfig, nil] config
  #
  # @return [Hash]
  #
  def field_value_pairs(
    item =  nil,
    pairs:  nil,
    before: nil,
    after:  nil,
    config: nil,
    **
  )
    parts = []
    if before.is_a?(Hash)
      parts << before
    elsif before
      Log.warn { "#{__method__}: before: unexpected: #{before.inspect}" }
    end

    pairs = item || pairs || object
    pairs = pairs.page_items if pairs.is_a?(Paginator)
    parts +=
      Array.wrap(pairs).map { |part|
        case part
          when Model
            fields   = part.fields
            config ||= model_context_fields || model_index_fields
            config.keys.map { |k|
              v = fields.key?(k) ? fields[k] : list_field_value(nil, field: k)
              [k, v]
            }.to_h
          when Hash
            part
          else
            Log.warn { "#{__method__}: unexpected: #{part.inspect}" }
        end
      }.compact

    if after.is_a?(Hash)
      parts << after
    elsif after
      Log.warn { "#{__method__}: after: unexpected: #{after.inspect}" }
    end

    {}.merge!(*parts)
  end

  # Local options for #field_property_pairs.
  #
  # @type [Array<Symbol>]
  #
  FIELD_PROPERTY_PAIRS_OPT =
    (%i[action only except field_root] + FIELD_VALUE_PAIRS_OPT).freeze

  # A table of fields with their property objects.
  #
  # @param [String, Symbol, nil]        action
  # @param [Array<Symbol>, nil]         only        Only matching fields.
  # @param [Array<Symbol>, nil]         except      Not matching fields.
  # @param [Symbol, Array<Symbol>, nil] field_root  Limits field configuration.
  # @param [Hash]                       opt         To #field_value_pairs.
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  # === Usage Notes
  # If *field_root* is given it is used to transform the field into a path
  # into the configuration.  The only current use is to allow specification of
  # :file_data so that configuration lookup is limited to the hierarchy within
  # the configuration for :file_data.  (This allows [:file_data][:id] to be
  # associated with the proper field configuration.)
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def field_property_pairs(
    action:     nil,
    only:       nil,
    except:     nil,
    field_root: nil,
    **opt
  )
    action &&= action.to_sym
    only   &&= Array.wrap(only).presence
    except &&= Array.wrap(except).presence
    field_value_pairs(**opt).map { |k, v|

      field, value, prop = k, v, nil
      if v.is_a?(Symbol)
        field = v
      elsif k.is_a?(Symbol) && v.is_a?(FieldConfig)
        prop  = v
        value = prop[:value]
      end

      if field_root
        field  = [field_root, field]
        prop   = field_configuration(field, action)
      elsif field.is_a?(String)
        prop ||= field_configuration_for_label(field, action)
        field  = prop[:field] if prop&.dig(:field)&.is_a?(Symbol)
      end

      next if only && !only.include?(field) || except&.include?(field)

      prop ||= field_configuration(field, action)
      prop   = prop.dup if prop&.frozen?

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

  # Render a value for use on an input form.
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt               Passed to render method except for:
  #
  # @option opt [String] :base
  # @option opt [String] :name
  # @option opt [Symbol] :type
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_field_item(name, value, **opt)
    normalize_attributes!(opt)
    trace_attrs!(opt)
    local = opt.extract!(:base, :name, :type)
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
        else value.map { |v| v.to_s.strip }.compact_blank!.join('; ')
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
  # @param [String]      name
  # @param [*]           value
  # @param [Symbol, nil] tag
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_check_box(name, value, tag: :li, css: '.checkbox.single', **opt)
    normalize_attributes!(opt)
    trace_attrs!(opt)
    outer    = remainder_hash!(opt, *CHECK_OPTIONS)
    t_opt    = trace_attrs_from(outer)
    checked  = opt.delete(:checked)
    label    = opt.delete(:label) || value

    # Checkbox control.
    cb_opt   = t_opt.merge(opt)
    checkbox = h.check_box_tag(name, value, checked, cb_opt)

    # Label for checkbox.
    lbl_opt  = t_opt.merge(for: opt[:id]).compact
    label    = h.label_tag(name, label, lbl_opt)

    # Checkbox/label combination.
    prepend_css!(outer, css)
    html_tag(tag, **outer) do
      checkbox << label
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether the value is a valid range type.
  #
  # @param [*]       range
  # @param [Boolean] fatal            If *true*, raise an exception if invalid.
  #
  # @raise [RuntimeError]             If not valid and *fatal* is *true*.
  #
  def valid_range?(range, fatal: false)
    valid = range.is_a?(Class) && [EnumType, Model].any? { |t| range < t }
    fatal &&= !valid
    raise "range: #{range.inspect}: not a subclass of EnumType" if fatal
    valid
  end

  # Translate attributes.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The potentially-modified *opt* hash.
  #
  # === Implementation Notes
  # Disabled input fields are given the :readonly attribute because setting the
  # :disabled attribute would prevent those fields from being included in the
  # data sent with the form submission.
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
    may_be_overridden or {}
  end

  # Return with the CSS classes associated with the items field scope(s).
  #
  # @param [Array, Symbol, String, nil] value
  #
  # @return [Array<String>]
  #
  #--
  # === Variations
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
    # noinspection RubyArgCount
    levels = levels&.select { |s| s.is_a?(Symbol) || s.is_a?(String) } || []
    levels.map! { |s| "scope-#{s}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # All known EMMA record fields (including those not currently in use).
  #
  # @type [Array<Symbol>]
  #
  EMMA_DATA_FIELDS = DataHelper::EMMA_DATA_FIELDS

  # EMMA data field prefixes with trailing underscore for #model_html_id.
  #
  # @type [Array<String>]
  #
  FIELD_PREFIX =
    EMMA_DATA_FIELDS.map { |f| f.to_s.sub(/_.*$/, '_') }.uniq.deep_freeze

  # Suffixes indicating field names to be preserved in #model_html_id.
  #
  # @type [Array<String>]
  #
  RESERVED_SUFFIX = %w[_data _date].freeze

  # Create a base for .field-* and .value-* classes.
  #
  # @param [Symbol, String, nil] base   Default: 'None'.
  #
  # @return [String]
  #
  def model_html_id(base)
    name = base.to_s.strip
    unless name.end_with?(*RESERVED_SUFFIX)
      FIELD_PREFIX.find { |prefix| name.delete_prefix!(prefix) }
    end
    name = 'None' if name.blank?
    html_id(name, camelize: true)
  end

  # Create a base for label and value identifiers.
  #
  # @param [Symbol, String, nil]  name
  # @param [String, nil]          base
  # @param [Symbol, nil]          field
  # @param [String, Symbol, nil]  label
  # @param [String, Integer, nil] index
  # @param [String, Symbol, nil]  group
  # @param [Hash]                 opt       Passed to #html_id.
  #
  # @return [String]
  #
  def field_html_id(
    name =  'field',
    base:   nil,
    field:  nil,
    label:  nil,
    index:  nil,
    group:  nil,
    **opt
  )
    base ||= model_html_id(field || label)
    # noinspection RubyMismatchedArgumentType
    html_id(name, base, group, index, underscore: false, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # format_org
  #
  # @param [*] value
  #
  # @return [String, nil]
  #
  def format_org(value, **)
    return EMPTY_VALUE          if value.blank?
    return value                if value.is_a?(String)
    id    = (value              if value.is_a?(Integer))
    id  ||= (value.org_id       if value.is_a?(ApplicationRecord))
    value = Org.none            if id == Org::INTERNAL_ID
    value = Org.find_by(id: id) if id && !value.is_a?(Org)
    value.abbrev                if value.is_a?(Org)
  end

  # format_user
  #
  # @param [*] value
  #
  # @return [String, nil]
  #
  def format_user(value, **)
    return EMPTY_VALUE if value.blank?
    # noinspection RubyMismatchedReturnType
    case value
      when Integer, String, User then User.account_name(value)
      when ApplicationRecord     then User.account_name(value.user_id)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render a value into ISO 8601 format if possible.
  #
  # @param [*] value
  #
  # @return [String, nil]
  #
  def format_datetime(value)
    return if value.blank? || (value == EMPTY_VALUE)
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
  # @param [String, Array]  text
  # @param [String, Regexp] separator
  #
  # @return [Array<String>]
  #
  # === Usage Notes
  # Descriptions like this don't currently seem to appear very often in search
  # results.  Even for those that do, they may not adhere to the expected
  # layout of information, and this method may not be that beneficial in those
  # cases.
  #
  def format_description(text, separator: / *; */, **)
    if text.is_a?(Array)
      return value.flat_map { |v| send(__method__, v, separator: separator) }
    end
    # Look for signs of structure, otherwise just treat as unstructured.
    # noinspection RubyMismatchedArgumentType
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
          # === Rare type of table-of-contents listing entry
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
    }.compact.map! { |line| line.gsub(/---/, EM_DASH).gsub(/--/, EN_DASH) }
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
  # @param [String, Array]  text
  # @param [String, Regexp] separator
  #
  # @return [Array<String>]
  #
  def format_multiline(text, separator: / *[;\n] */, **)
    Array.wrap(text).flat_map { |s| s.to_s.split(separator) }.compact_blank!
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  VALID_LANG   = config_text(:fields, :valid_lang).freeze
  INVALID_LANG = config_text(:fields, :invalid_lang).freeze
  INVALID_ID   = config_text(:fields, :invalid_id).freeze

  # Wrap invalid language values in a *span*.
  #
  # @param [Any]     value            Value to check.
  # @param [Boolean] code             If *true* display the ISO 639 code.
  #
  # @return [ActiveSupport::SafeBuffer, String, Array]
  #
  #--
  # === Variations
  #++
  #
  # @overload mark_invalid_languages(value, code: false)
  #   @param [String]        value
  #   @param [Boolean]       code
  #   @return [ActiveSupport::SafeBuffer, String, nil]
  #
  # @overload mark_invalid_languages(array, code: false)
  #   @param [Array<String>] array
  #   @param [Boolean]       code
  #   @return [Array<ActiveSupport::SafeBuffer, String>]
  #
  def mark_invalid_languages(value, code: false, **)
    if value.is_a?(Array)
      value.map { |v| send(__method__, v, code: code) }
    elsif !(lang = LanguageType.cast(value, warn: false, invalid: true))
      value
    elsif !lang.valid?
      html_span(value, class: 'invalid', title: INVALID_LANG)
    elsif code
      lang.code
    elsif value.casecmp?(lang.label)
      value
    else
      html_span(lang.label, title: (VALID_LANG % value))
    end
  end

  # Wrap invalid identifier values in a *span*.
  #
  # @param [Any] value                Value to check.
  #
  # @return [ActiveSupport::SafeBuffer, String, Array]
  #
  #--
  # === Variations
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
  def mark_invalid_identifiers(value, **)
    return value.map { |v| send(__method__, v) } if value.is_a?(Array)
    type, id_part = value.to_s.split(':', 2)
    if id_part.nil? # No type prefix.
      value
    elsif (identifier = PublicationIdentifier.create(id_part, type))&.valid?
      identifier.to_s
    else
      tooltip = interpolate_named_references(INVALID_ID, type: type)
      html_span(value, class: 'invalid', title: tooltip)
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
