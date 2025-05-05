# app/decorators/base_decorator/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting display of individual Model instances.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module BaseDecorator::List

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Fields
  include BaseDecorator::Pagination

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default CSS class for wrapping label/values pairs (when requested).
  #
  # @type [String]
  #
  PAIR_WRAPPER = 'pair'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Heading element for lists of model items.
  #
  # @param [Array, nil]       list
  # @param [Integer]          level
  # @param [String, nil]      title
  # @param [Integer, Boolean] count   Default: `object.size`.
  # @param [String]           css     Characteristic CSS class/selector.
  # @param [Hash]             opt     Passed to heading element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_heading(
    list =  nil,
    level:  1,
    title:  nil,
    count:  true,
    css:    '.list-heading',
    **opt
  )
    list ||= object
    title  = ERB::Util.h(page_title(title))
    count  = list.size unless count.is_a?(Integer) || count.is_a?(FalseClass)
    prepend_css!(opt, 'empty') if list.blank?
    prepend_css!(opt, css)
    html_tag(level, **opt) do
      count ? label_with_count(title, count) : title
    end
  end

  # Append a parenthesized count to a label.
  #
  # @param [String]      label
  # @param [Integer]     count        Wrapped in a `span` element.
  # @param [String, nil] unit         Appended to the displayed count value.
  # @param [String]      css          CSS class/selector for count element.
  # @param [Hash]        opt          Passed to count element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def label_with_count(label, count, unit: nil, css: '.total-count', **opt)
    count = html_span(count, **prepend_css!(opt, css))
    count = unit ? "(#{count} #{ERB::Util.h(unit)})" : "(#{count})"
    safe_join([label, count.html_safe], ' ')
  end

  # thumbnail_data
  #
  # @return [String, nil]
  #
  def thumbnail_data
    context_value(:thumbnail, :thumbnail_image)
  end

  # cover_data
  #
  # @return [String, nil]
  #
  def cover_data
    context_value(:cover, :cover_image)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render field/value pairs.
  #
  # @param [String, nil] separator    Default: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]        opt          To #render_pair or #property_pairs.
  #
  # @option opt [Integer] :index      Offset to make unique element IDs passed
  #                                     to #render_pair.
  #
  # @option opt [Hash] :fake_upload_file  Special data only for Uploads passed
  #                                         through #list_field_values to
  #                                         #property_pairs and on to
  #                                         UploadDecorator#value_pairs.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_values(separator: nil, **opt)
    vp_opt = opt.extract!(*VALUE_PAIRS_OPT).compact_blank
    return ''.html_safe if blank? && vp_opt.blank?
    opt.delete(:level) # Not propagated in the general case.

    trace_attrs!(opt, __method__)
    t_opt  = trace_attrs_from(opt)
    fv_opt = opt.slice(:index, :no_fmt)
    pp_opt = opt.extract!(*PROPERTY_PAIRS_OPT, :fake_upload_file)
    separator ||= DEFAULT_ELEMENT_SEPARATOR

    pairs = list_field_values(**vp_opt, **pp_opt, **fv_opt, **t_opt)
    pairs.map.with_index(1) { |(field, prop), pos|
      label = prop[:label] || labelize(field)
      value = prop[:value]
      list_render_pair(label, value, field: field, prop: prop, pos: pos, **opt)
    }.compact.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair in a list item.
  #
  # @param [String, Symbol, nil] label
  # @param [any, nil]            value
  # @param [Symbol]              field
  # @param [FieldConfig]         prop
  # @param [Hash]                opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # === Implementation Notes
  # Compare with BaseDecorator::Grid#grid_data_cell_render_pair
  #
  def list_render_pair(label, value, field:, prop:, **opt)
    scopes = field_scopes(field).presence and append_css!(opt, *scopes)
    trace_attrs!(opt, __method__)
    render_pair(label, value, field: field, prop: prop, **opt)
  end

  DEF_LABEL_CLASS = 'label'
  DEF_VALUE_CLASS = 'value'

  # Fields which, when formatting, should be rendered as 'textarea' values.
  #
  # @type [Array<Symbol>]
  #
  TEXTAREA_FIELDS = %i[
    dc_description
    emma_lastRemediationNote
    rem_comments
    rem_remediationComments
    s_accessibilitySummary
  ].freeze

  # Render a single label/value pair.
  #
  # @param [String, Symbol, nil]  label
  # @param [any, nil]             value
  # @param [FieldConfig, nil]     prop      Default: from field/model.
  # @param [Symbol, nil]          field
  # @param [String, Integer]      index     Offset to make unique element IDs.
  # @param [Integer, nil]         row       Display row.
  # @param [Integer, nil]         col       Display column.
  # @param [Integer, nil]         pos       Ordinal alternative to row or col.
  # @param [String, nil]          separator Between parts if *value* is array.
  # @param [String, nil]          wrap      Class for outer wrapper.
  # @param [Symbol]               tag       @see #HTML_TABLE_TAGS
  # @param [Boolean,Symbol,Array] no_fmt
  # @param [Boolean]              no_code
  # @param [Boolean]              no_label
  # @param [Boolean]              no_help
  # @param [String, nil]          label_css
  # @param [String, nil]          value_css
  # @param [Hash]                 opt       Passed to each #html_div except:
  #
  # @option opt [String]         :base              Passed to #field_html_id.
  # @option opt [String, Symbol] :group             Passed to #field_html_id.
  #
  # @option opt [String]         :role              To outer wrapper only.
  # @option opt [any, nil]       :'aria-level'      To outer wrapper only.
  # @option opt [any, nil]       :'aria-colindex'   To outer wrapper only.
  #
  # @option opt [String]         :label_id          Specify label element ID.
  # @option opt [String]         :value_id          Specify value element ID.
  # @option opt [Hash, nil]      :field_error       Special for ManifestItem
  # @option opt [any, nil]       :'data-raw-value'  Override for value element.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @yield [fld, val, prp, **o] To supply part(s) after the .value element.
  # @yieldparam [Symbol]      fld     The field.
  # @yieldparam [any, nil]    val     The raw value.
  # @yieldparam [FieldConfig] prp     The adjusted field properties.
  # @yieldparam [Hash]        o       Options for #html_div.
  # @yieldreturn [Array, ActiveSupport::SafeBuffer, nil]
  #
  # === Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  # While the base implementation of this method does not actually return *nil*
  # callers should be prepared to handle that possibility, since subclass
  # override(s) may return *nil*.
  #
  def render_pair(
    label,
    value,
    prop:       nil,
    field:      nil,
    index:      nil,
    row:        nil,
    col:        nil,
    pos:        nil,
    separator:  nil,
    wrap:       nil,
    tag:        :div,
    no_fmt:     nil,
    no_code:    nil,
    no_label:   nil,
    no_help:    nil,
    label_css:  DEF_LABEL_CLASS,
    value_css:  DEF_VALUE_CLASS,
    **opt
  )
    prop  ||= field_configuration(field)
    field ||= prop[:field]
    label   = prop[:label] || label
    tooltip = (prop[:tooltip] unless field == :dc_title)

    # Setup options for creating related HTML identifiers.
    base    = opt.delete(:base) || model_html_id(field || label)
    classes = %W[field-#{base}]
    base    = "Emma#{base}" if field == :emma_repository
    id_opt  = { base: base, index: index, group: opt.delete(:group) }.compact
    l_id    = opt.delete(:label_id)
    v_id    = opt.delete(:value_id) || field_html_id(value_css, **id_opt)
    v_dv    = opt[:'data-raw-value']

    # Extract range values.
    case (raw_val = value)
      when FieldConfig
        multi = value[:array]
        value = value[:value]
      when Field::Type
        multi = (value.mode == :multiple)
        value = value.content
      else
        multi = true?(prop[:array])
    end

    # Adjust field properties.
    type   = prop[:type]
    cls    = type.is_a?(Class)
    enum   = cls && (type < EnumType)
    model  = cls && (type < Model)
    no_fmt = [no_fmt]               if no_fmt.is_a?(Symbol)
    no_fmt = no_fmt.include?(field) if no_fmt.is_a?(Array)
    if Array.wrap(value).first.is_a?(ActiveSupport::SafeBuffer)
      no_fmt = true
    elsif enum || model
      array  = value.is_a?(Array)
      value  = value.split(/[,;|\t\n]/) if value.is_a?(String)
      value  = Array.wrap(value).compact_blank
      value.map! { type.cast(_1, warn: false) || _1 } if enum
      value.map! { type.instance_for(_1)      || _1 } if model
      v_dv ||= value.join('|')
      value  = value.first unless array || value.many?
    end

    # Format the content of certain fields.
    unless no_fmt
      value = render_format(field, value, code: !no_code) || value
      array = value.is_a?(Array)
      if enum || model
        value = Array.wrap(value).map! { _1.try(:label) || _1 }
        value = value.first unless array
      elsif TEXTAREA_FIELDS.include?(field)
        prop = prop.merge(type: 'textarea') if array && value.many?
      end
    end

    # Special for ManifestItem
    error   = opt.delete(:field_error)&.dig(field.to_s)&.presence
    err_val = error&.keys&.then { _1.many? ? _1 : _1.first }

    # Pre-process value(s), wrapping each array element in a `<div>`.
    if prop[:array] && !no_fmt
      value = value.split("\n") if value.is_a?(String)
      value = Array.wrap(value).compact_blank
      value.map!.with_index(1) do |v, i|
        v_opt = { class: "item item-#{i}" }
        append_css!(v_opt, 'error') if error&.key?(v.to_s)
        html_div(v, **v_opt)
      end
      separator ||= "\n"
    end
    value = value.first if value.is_a?(Array) && !value.many? && !multi
    if value.is_a?(Array)
      separator ||= no_fmt ? "\n" : HTML_BREAK
      value = safe_join(value, separator)
    elsif err_val
      value = err_val
    end

    # Extract attributes that are appropriate for the wrapper element which
    # should not propagate into the label, value, or other enclosed elements.
    role    = opt.delete(:role)
    level   = opt.delete(:'aria-level')
    col_idx = opt.delete(:'aria-colindex')

    # CSS classes for both label and value.
    unless field == :dc_title
      if prop[:array]
        classes << 'multi' if multi
        classes << 'array'
      else
        case type
          when 'textarea' then classes << 'textbox'
          when 'number'   then classes << 'numeric'
          when 'json'     then classes << 'hierarchy'
          else                 classes << type unless cls
        end
      end
      classes << 'enum'  if enum
      classes << 'model' if model
    end
    classes << "pos-#{pos}" if pos
    classes << "col-#{col}" if col
    classes << "row-#{row}" if row
    prepend_css!(opt, *classes)

    # Explicit 'data-*' attributes.
    opt.merge!(prop.select { |k, _| k.start_with?('data-') })
    opt[:'data-field'] ||= field
    trace_attrs!(opt, __method__)
    parts = []

    # Label and label HTML options.
    if no_label || label.blank?
      l_id = nil
    else
      # Wrap label text in a <span> if needed; append help icon if applicable.
      help  = (prop[:help].presence unless no_help)
      html  = label.is_a?(ActiveSupport::SafeBuffer)
      label = label.dup if help && html
      label = html_span(class: 'text') { label || labelize(field) } unless html
      label << render_help_icon(field, value, *help) if help
      l_tag   = wrap ? :div : tag
      l_id  ||= field_html_id(DEF_LABEL_CLASS, **id_opt)
      l_opt   = prepend_css(opt, label_css)
      l_opt[:id]    = l_id    if l_id
      l_opt[:title] = tooltip if tooltip && !wrap
      parts << html_tag(l_tag, label, **l_opt)
    end

    # Value and value HTML options.
    v_tag = wrap ? :div : tag
    v_opt = prepend_css(opt, value_css)
    v_opt[:id]                 = v_id    if v_id
    v_opt[:title]              = tooltip if tooltip && !wrap
    v_opt[:'data-raw-value']   = v_dv    if v_dv
    v_opt[:'aria-describedby'] = l_id    if l_id
    parts << html_tag(v_tag, value, **v_opt)

    # Optional additional element(s).
    if block_given?
      b_opt = l_id ? opt.merge('aria-describedby': l_id) : opt
      parts.concat Array.wrap(yield(field, raw_val, prop, **b_opt))
    end

    # Pair wrapper.
    if wrap
      wrap  = PAIR_WRAPPER if wrap.is_a?(TrueClass)
      w_opt = prepend_css(opt, wrap)
      w_opt[:id]                ||= field_html_id(wrap, **id_opt)
      w_opt[:role]              ||= role
      w_opt[:title]             ||= tooltip
      w_opt[:'aria-level']      ||= level
      w_opt[:'aria-colindex']   ||= col_idx
      w_opt[:'aria-labelledby'] ||= l_id  if l_id
      append_css!(w_opt, 'error')         if error
      html_tag(tag, *parts, **w_opt)
    else
      safe_join(parts)
    end
  end

  # Apply formatting appropriate to *field*.
  #
  # @param [Symbol]      field
  # @param [any, nil]    value
  # @param [Hash]        opt          Options for #mark_invalid_languages.
  #
  # @return [Array<String>, String, nil]
  #
  def render_format(field, value, **opt)
    case field
      when :org,  :org_id            then :format_org
      when :user, :user_id           then :format_user
      when :dc_description           then :format_description
      when :dc_language              then :mark_invalid_languages
      when :dc_identifier            then :mark_invalid_identifiers
      when :dc_relation              then :mark_invalid_identifiers
      when :emma_lastRemediationNote then :format_multiline
      when :rem_comments             then :format_multiline
      when :rem_remediationComments  then :format_multiline
      when :s_accessibilitySummary   then :format_multiline
    end.then { send(_1, value, **opt) if _1 }
  end

  # Generate a help icon relevant to *field*.
  #
  # @param [Symbol]               field
  # @param [any, nil]             value
  # @param [Array<Symbol,String>] help    Help topic(s).
  # @param [String, Symbol, nil]  topic
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Implementation Notes
  # To accommodate ACE items, an assumption is being made that this method is
  # only ever called for the decorator's object (and not for an arbitrary
  # label/value pair outside of that context).
  #
  def render_help_icon(field, value, *help, topic: nil, **)
    if field == :emma_retrievalLink
      topic ||= repository_for(extract_url(value), object)
    end
    help = help.many? ? [*help[...-1], topic] : [*help, topic] if topic
    h.help_popup(*help)
  end

  # Displayed in place of a results list.
  #
  # @type [String]
  #
  NO_RESULTS = config_term(:list, :no_results).freeze

  # An indicator that can be used to stand for an empty list.
  #
  # @param [String] message           Default: #NO_RESULTS.
  # @param [Hash]   opt               To #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_empty_value(message: NO_RESULTS, **opt)
    render_pair(nil, message, **opt, index: hex_rand)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # From `opt[:prop]` (or #object by default), return fields and configurations
  # augmented with a `:value` entry containing the value for the field.
  #
  # @param [Boolean] limited          Do not include fields that are :ignored
  #                                     or have the wrong :role.
  # @param [Hash]    opt              Passed to #property_pairs and
  #                                     #list_field_value.
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  def list_field_values(limited: true, **opt)
    trace_attrs!(opt, __method__)
    t_opt = trace_attrs_from(opt)
    v_opt = opt.extract!(:index, :no_fmt).merge!(t_opt)
    property_pairs(**opt).map { |field, prop|
      next if limited && (prop[:ignored] || !user_has_role?(prop[:role]))
      prop[:value] = list_field_value(prop[:value], field: field, **v_opt)
      [field, prop]
    }.compact.to_h
  end

  # Transform a field value for HTML rendering.
  #
  # @param [any, nil]    value
  # @param [Symbol, nil] field
  # @param [Hash]        opt          Passed to #access.
  #
  # @return [any]                     HTML or scalar value.
  # @return [nil]                     If *value* or *object* is *nil*.
  #
  def list_field_value(value, field:, **opt)
    value = field_value(nil, field, opt) if value.nil? && field.is_a?(Symbol)
    value = value.value                  if value.is_a?(Field::Type)
    value = value.to_s                   if value.is_a?(FalseClass)
    value
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Enable to log attempts to render a field which fail.
  #
  # @type [Boolean]
  #
  DEBUG_DECORATOR_EXECUTE = true?(ENV_VAR['DEBUG_DECORATOR_EXECUTE'])

  # Attempt to interpret *method* as an `*item*` method or as a method defined
  # in the current context.
  #
  # @param [Model, Hash, nil] item    Default: `#object`.
  # @param [Symbol]           m
  # @param [Hash, nil]        opt     Options (used only if appropriate).
  #
  # @return [any]                     HTML or scalar value.
  # @return [nil]                     If executed method returned *nil*.
  #
  def field_value(item, m, opt = nil)
    item ||= object
    if (data = item.try(:emma_metadata))&.key?(m)
      data[m]
    elsif item.try(:extended_field_names)&.include?(m)
      item.extended_fields(m).values.first
    elsif item.try(:key?, m)
      item[m]
    elsif item.respond_to?(m)
      kw = opt.present?
      if kw && item.method(m).parameters.any? { |p, _| p.start_with?('key') }
        item.send(m, **opt)
      else
        item.send(m)
      end
    elsif respond_to?(m)
      kw, args = method(m).parameters.partition { |p, _| p.start_with?('key') }
      item = (item.presence if args.present?)
      opt  = (opt.presence  if kw.present?)
      case
        when item && opt then send(m, item, **opt)
        when item        then send(m, item)
        when opt         then send(m, **opt)
        else                  send(m)
      end
    elsif DEBUG_DECORATOR_EXECUTE
      Log.warn do
        "#{self.class}.field_value(#{item.class}): #{m.inspect} not usable"
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a metadata listing of a model instance.
  #
  # @param [Hash]        outer        HTML options for outer div.
  # @param [String, nil] css          Default: "#(model_type)-details"
  # @param [Hash]        opt          Passed to #render_field_values except:
  #
  # @option opt [String] :class       Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details(outer: nil, css: nil, **opt)
    trace_attrs!(opt, __method__)
    pairs   = list_field_values(**opt)
    count   = list_item_columns(pairs)
    css   ||= "#{model_type}-details"
    classes = [css, opt.delete(:class)]
    classes.push("columns-#{count}", "count-#{count}") if count.positive?
    outer   = prepend_css(outer, *classes)
    t_opt   = trace_attrs_from(opt)
    html_div(**outer, **t_opt) do
      render_field_values(pairs: pairs, **opt)
    end
  end

  # Render an element containing a metadata listing of a model instance.
  #
  # @param [Array]               before   Optional elements before the details.
  # @param [Integer, nil]        level
  # @param [String, Symbol, nil] role
  # @param [String, nil]         css      Default: "#(model_type)-container"
  # @param [Hash]                opt      Passed to #details.
  # @param [Proc, nil]           blk      Passed to #capture.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*before, level: nil, role: nil, css: nil, **opt, &blk)
    css  ||= ".#{model_type}-container"
    role ||= (:article if level == 1)
    opt.delete(:skip) # In case this slipped in to the base method.
    trace_attrs!(opt, __method__)

    parts  = before
    parts << details(**opt)
    parts << h.capture(&blk) if blk

    outer = trace_attrs_from(opt)
    outer.merge!(role: role) if role
    prepend_css!(outer, css)
    html_div(*parts, **outer)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A complete list item entry.
  #
  # @param [Array<Symbol>] skip       Display aspects to avoid.
  # @param [Hash]          opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_row(skip: [], **opt)
    opt[:id] ||= model_item_id
    l     = opt.delete(:level)
    skip  = Array.wrap(skip)
    trace_attrs!(opt, __method__)
    parts = []
    parts << list_item_number(level: l, **opt) unless skip.include?(:number)
    parts << thumbnail(link: true, **opt)      unless skip.include?(:thumbnail)
    parts << list_item(**opt)
    safe_join(parts)
  end

  # Method options which are processed internally and not passed on as HTML
  # options.
  #
  # @type [Array<Symbol>]
  #
  ITEM_ENTRY_OPT = %i[index group row level skip].freeze

  # Render an element containing the ordinal position of an entry within a list
  # based on the provided *offset* and *index*.
  #
  # *1* Use :inner to pass additional element(s) to go inside the container; if
  #     given as *true* this specifies that elements from the block will go
  #     inside the container (this is the default unless :outer is given).
  #
  # *2* Use :outer to pass additional element(s) to go after the container
  #     element; if given as *true* this specifies that elements from the block
  #     will go after the container.
  #
  # @param [Integer]                index   Index number.
  # @param [Integer, nil]           level   Heading tag level (@see #html_tag).
  # @param [String, nil]            group   Sets :'data-group' for outer div.
  # @param [Integer, nil]           row
  # @param [Boolean, String, Array] inner   *1* above.
  # @param [Boolean, String, Array] outer   *2* above.
  # @param [String]                 css     Characteristic CSS class/selector.
  # @param [Hash]                   opt     Passed to inner #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield To supply additional parts within .number element.
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>,ActiveSupport::SafeBuffer]
  #
  def list_item_number(
    index:,
    level:  nil,
    group:  nil,
    row:    nil,
    inner:  nil,
    outer:  nil,
    css:    '.number',
    **opt
  )
    index  = non_negative(index) or return
    row    = positive(row)

    opt.except!(*ITEM_ENTRY_OPT)
    trace_attrs!(opt, __method__)
    t_opt  = trace_attrs_from(opt)

    # Set up number label and inner parts if supplied.
    inner_parts = []
    inner_parts << list_item_number_label(index: index, **t_opt)
    inner_parts.concat(Array.wrap(inner)) if inner

    # Set up outer parts if supplied.
    outer_parts = []
    outer_parts.concat(Array.wrap(outer)) if outer

    # Additional elements supplied by the block:
    if block_given? && (added = Array.wrap(yield)).present?
      if inner.is_a?(TrueClass) || outer.nil? || outer.is_a?(FalseClass)
        inner_parts.concat(added)
      else
        outer_parts.concat(added)
      end
    end

    # Wrap parts in a container for group positioning:
    inner_opt = prepend_css(opt, 'container')
    inner_opt[:id] &&= "#{inner_opt[:id]}-container"
    container = html_tag(level, inner_parts, **inner_opt)

    # Wrap the container in the actual number grid element.
    outer_opt = t_opt.merge(id: opt[:id])
    outer_opt[:id] &&= "#{outer_opt[:id]}-number"
    prepend_css!(outer_opt, css)
    append_css!(outer_opt, 'empty')      if blank?
    append_css!(outer_opt, "row-#{row}") if row
    outer_opt[:'data-group']    = group  if group
    outer_opt[:'data-title_id'] = object.try(:emma_titleId)
    html_div(container, outer_parts, **outer_opt)
  end

  ONE_ENTRY  = config_term(:list, :one_entry).freeze
  NO_ENTRIES = config_term(:list, :no_entries).freeze

  # list_item_number_label
  #
  # @param [Integer,nil] index
  # @param [String]      label        Alternate label contents.
  # @param [String]      value        Alternate value contents.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item_number_label(index: nil, label: nil, value: nil, **opt)
    trace_attrs!(opt, __method__)

    # Label visible only to screen-readers:
    l_opt   = prepend_css(opt, 'sr-only')
    label ||= index ? "#{ONE_ENTRY} " : NO_ENTRIES
    label   = html_span(label, **l_opt)

    # Visible item number value:
    v_opt   = prepend_css(opt, 'value')
    value ||= index ? "#{index + 1}" : ''
    value   = html_span(value, **v_opt)

    label << value
  end

  # Render a single entry for use within a list of items.
  #
  # @param [String, Array] before     Optional leading column(s).
  # @param [String, Array] after      Optional trailing columns(s).
  # @param [Hash]          outer      HTML options for outer div container.
  # @param [Symbol]        tag        If :tr, generate <tr>.
  # @param [Symbol]        render     Default: #render_field_values.
  # @param [Integer, nil]  level
  # @param [String]        css        Default: .(model_type)-list-item
  # @param [String]        id         Passed to :outer div.
  # @param [Hash]          opt        Passed to the render method except or
  #                                     #list_field_values.
  #
  # @option opt [Integer] :row        Sets "row-#{row}" in :outer div.
  # @option opt [Integer] :col        Sets "col-#{col}" in :outer div.
  # @option opt [Integer] :pos        Sets "pos-#{pos}" in :outer div.
  # @option opt [Symbol]  :group      May set :'data-group' for :outer div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(
    before: nil,
    after:  nil,
    outer:  nil,
    tag:    :div,
    render: nil,
    level:  nil,
    css:    nil,
    id:     nil,
    **opt
  )
    trace_attrs!(opt, __method__)
    css   ||= ".#{model_type}-list-item"
    row     = positive(opt[:row])
    col     = positive(opt[:col])
    pos     = positive(opt[:pos])
    role    = opt.delete(:role)
    group   = opt[:group] ||= state_group

    pairs   = list_field_values(**opt)
    count   = list_item_columns(pairs)

    row_opt = prepend_css(outer, css)
    row_opt[:id]              ||= id   || model_item_id(**opt)
    row_opt[:role]            ||= role || ('heading' if level)
    row_opt[:'data-group']    ||= group
    row_opt[:'data-title_id'] ||= title_id_values
    row_opt[:'aria-level']    ||= level
    row_opt.delete(:'aria-rowindex')         unless for_html_table?(tag)
    row_opt.delete(:'aria-colindex')
    append_css!(row_opt, "columns-#{count}") if count.positive?
    append_css!(row_opt, "pos-#{pos}")       if pos
    append_css!(row_opt, "col-#{col}")       if col
    append_css!(row_opt, "row-#{row}")       if row
    append_css!(row_opt, 'empty')            if blank?

    html_tag(tag, **row_opt) do
      before &&= Array.wrap(before).compact_blank.map! { ERB::Util.h(_1) }
      after  &&= Array.wrap(after).compact_blank.map!  { ERB::Util.h(_1) }
      render = :render_empty_value  if blank?
      render = :render_field_values if render.nil?
      pairs  = send(render, pairs: pairs, **opt, level: level&.next)
      [*before, *pairs, *after]
    end
  end

  # The number of columns needed if `*item*` will be displayed horizontally.
  #
  # @param [any, nil] item            Model, Hash, Array; default: `#object`.
  #
  # @return [Integer]
  #
  def list_item_columns(item = nil)
    item = object          if item.nil?
    item = item.attributes if item.is_a?(Model)
    item = item.keys       if item.is_a?(Hash)
    Array.wrap(item).reject { _1.is_a?(FieldConfig) && _1[:ignored] }.size
  end

  # Thumbnail element for the given catalog title.
  #
  # @param [Boolean, String] link         If *true* make the image a link to
  #                                         the show page for the item.
  # @param [Boolean]         placeholder  If *false*, return *nil* if an image
  #                                         could not be determined.
  # @param [String]          css          Characteristic CSS class/selector.
  # @param [Hash]            opt          To ImageHelper#image_element except:
  #
  # @option opt [Symbol] :meth            Passed to #get_thumbnail_image
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def thumbnail(link: false, placeholder: true, css: '.thumbnail', **opt)
    ph    = placeholder.presence
    local = opt.extract!(:meth, :alt, *ITEM_ENTRY_OPT)
    prepend_css!(opt, css)
    if (url = get_thumbnail_image(**local))
      id   = object.identifier
      link = show_path(id: id) if link.is_a?(TrueClass)
      link = nil               if link.is_a?(FalseClass)
      alt  = local[:alt] || config_lookup('thumbnail.image.alt', item: id)
      row  = positive(local[:row])
      opt[:id] = "container-img-#{id}"
      opt[:'data-group'] = local[:group] if local[:group].present?
      opt[:'data-turbolinks-permanent'] = true
      image_element(url, link: link, alt: alt, row: row, **opt)
    end ||
      (ph && placeholder_element(comment: 'no thumbnail', **opt))
  end

  # Cover image element for the given catalog title.
  #
  # @param [Boolean, String] link         If *true* make the image a link to
  #                                         the show page for the item.
  # @param [Boolean]         placeholder  If *false*, return *nil* if an image
  #                                         could not be determined.
  # @param [String]          css          Characteristic CSS class/selector.
  # @param [Hash]            opt          To ImageHelper#image_element except:
  #
  # @option opt [Symbol] :meth            Passed to #get_cover_image
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def cover(link: false, placeholder: true, css: '.cover-image', **opt)
    ph    = placeholder.presence
    local = opt.extract!(:meth, :alt, *ITEM_ENTRY_OPT)
    prepend_css!(opt, css)
    if (url = get_cover_image(**local))
      id   = object.identifier
      link = show_path(id: id) if link.is_a?(TrueClass)
      link = nil               if link.is_a?(FalseClass)
      alt  = local[:alt] || config_lookup('cover.image.alt', item: id)
      row  = positive(local[:row])
      opt[:'data-group'] = local[:group] if local[:group].present?
      image_element(url, link: link, alt: alt, row: row, **opt)
    end ||
      (ph && placeholder_element(comment: 'no cover image', **opt))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # An "empty" element that can be used as a placeholder.
  #
  # @param [String, nil] comment      Text for an interior HTML comment.
  # @param [Symbol]      tag          The HTML tag to use for the element.
  # @param [Hash]        opt          Passed to #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def placeholder_element(comment: nil, tag: :div, **opt)
    html_tag(tag, 'aria-hidden': true, **opt) do
      "<!-- #{comment} -->".html_safe if comment.present?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a standardized (base) element identifier from the object.
  #
  # @param [Hash] opt                 Passed to #html_id.
  #
  # @return [String]
  #
  def model_item_id(**opt)
    obj = object.presence
    id  = obj.try(:submission_id) || obj.try(:identifier) || hex_rand
    html_id(model_type, id, underscore: false, **opt)
  end

  # All :emma_titleId value(s) associated with the object.
  #
  # @return [String,nil]
  #
  def title_id_values
    records = object.presence.try(:records)
    titles  = records&.map(&:emma_titleId)&.compact
    titles.uniq.join(',') if titles.present?
  end

  # state_group
  #
  # @return [Symbol, nil]
  #
  def state_group(...)
    object.presence.try(:state_group)
  end

  # get_thumbnail_image
  #
  # @param [Symbol, nil] meth
  #
  # @return [String, nil]
  #
  def get_thumbnail_image(meth: :thumbnail_image, **)
    @thumbnail ||= thumbnail_data
    @thumbnail ||=
      meth && (object.respond_to?(meth) ? object.send(meth) : try(meth))
  end

  # get_cover_image
  #
  # @param [Symbol, nil] meth
  #
  # @return [String, nil]
  #
  def get_cover_image(meth: :cover_image, **)
    @cover_image ||= cover_data
    @cover_image ||=
      meth && (object.respond_to?(meth) ? object.send(meth) : try(meth))
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
