# app/decorators/base_decorator/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting display of individual Model instances.
#
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
  # @param [Hash, nil]   pairs        Passed to #field_pairs.
  # @param [String, nil] separator    Default: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]        opt          To #render_pair except
  #                                     #FIELD_PAIRS_OPTIONS to #field_pairs.
  #
  # @option opt [Integer] :index      Offset to make unique element IDs passed
  #                                     to #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_values(pairs: nil, separator: nil, **opt)
    return ''.html_safe if pairs.nil? && object.nil?
    opt.delete(:level) # Not propagated in the general case.

    fp_opt      = opt.extract!(*FIELD_PAIRS_OPTIONS)
    value_opt   = opt.slice(:index, :no_format)
    opt[:row]   = 0
    separator ||= DEFAULT_ELEMENT_SEPARATOR

    field_pairs(pairs, **fp_opt).map { |field, prop|
      opt[:row] += 1
      label = prop[:label]
      value = render_value(prop[:value], field: field, **value_opt)
      p_opt = { field: field, prop: prop, **opt }
      render_field_value_pair(label, value, **p_opt)
    }.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair in a list item.
  #
  # @param [String, Symbol, nil] label
  # @param [*]                   value
  # @param [Symbol]              field
  # @param [Hash]                prop
  # @param [Hash]                opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Implementation Notes
  # Compare with BaseDecorator::Grid#grid_data_cell_render_pair
  #
  def render_field_value_pair(label, value, field:, prop:, **opt)
    rp_opt = opt.merge(field: field, prop: prop)
    scopes = field_scopes(field).presence and append_css!(rp_opt, *scopes)
    render_pair(label, value, **rp_opt)
  end

  DEFAULT_LABEL_CLASS = 'label'
  DEFAULT_VALUE_CLASS = 'value'

  # Render a single label/value pair.
  #
  # @param [String, Symbol, nil]  label
  # @param [*]                    value
  # @param [Hash, nil]            prop      Default: from field/model.
  # @param [Symbol, nil]          field
  # @param [String, Integer]      index     Offset to make unique element IDs.
  # @param [Integer, nil]         row       Display row.
  # @param [String, nil]          separator Between parts if *value* is array.
  # @param [String, nil]          wrap      Class for outer wrapper.
  # @param [Symbol]               tag       @see #HTML_TABLE_TAGS
  # @param [Boolean,Symbol,Array] no_format
  # @param [Boolean]              no_code
  # @param [Boolean]              no_label
  # @param [Boolean]              no_help
  # @param [String, nil]          label_css
  # @param [String, nil]          value_css
  # @param [Hash]                 opt       Passed to each #html_div except:
  #
  # @option opt [String] :role              Passed to outer wrapper only.
  # @option opt [String] :base
  # @option opt [String] :label_id
  # @option opt [String] :value_id
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [fld, val, prp, **o] To supply part(s) after the .value element.
  # @yieldparam [Symbol] fld          The field.
  # @yieldparam [*]      val          The raw value.
  # @yieldparam [Hash]   prp          The adjusted field properties.
  # @yieldparam [Hash]   o            Options for #html_div.
  # @yieldreturn [Array, ActiveSupport::SafeBuffer, nil]
  #
  # === Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def render_pair(
    label,
    value,
    prop:       nil,
    field:      nil,
    index:      nil,
    row:        nil,
    separator:  nil,
    wrap:       nil,
    tag:        :div,
    no_format:  nil,
    no_code:    nil,
    no_label:   nil,
    no_help:    nil,
    label_css:  DEFAULT_LABEL_CLASS,
    value_css:  DEFAULT_VALUE_CLASS,
    **opt,
    &block
  )
    prop  ||= field_configuration(field)
    field ||= prop[:field]
    label   = prop[:label] || label
    return if prop[:ignored]
    return unless user_has_role?(prop[:role])

    # Setup options for creating related HTML identifiers.
    base    = opt.delete(:base) || model_html_id(field || label)
    type    = "field-#{base}"
    id_opt  = { base: base, index: index, group: opt.delete(:group) }.compact
    l_id    = opt.delete(:label_id)
    v_id    = opt.delete(:value_id) || field_html_id(value_css, **id_opt)

    # Extract range values.
    value   = value.content if value.is_a?(Field::Type)
    raw_val = value

    # Format the content of certain fields.
    lines     = nil
    no_format = [no_format]               if no_format.is_a?(Symbol)
    no_format = no_format.include?(field) if no_format.is_a?(Array)
    unless no_format
      case field
        when :dc_description
          value = lines = format_description(value)
        when :rem_comments, :s_accessibilitySummary
          value = lines = format_multiline(value)
        when :emma_lastRemediationNote, :rem_remediationComments
          value = lines = format_multiline(value)
        when :dc_identifier, :dc_relation
          value = mark_invalid_identifiers(value)
        when :dc_language
          value = mark_invalid_languages(value, code: !no_code)
      end
    end

    # Adjust field properties.
    cls   = prop[:type].is_a?(Class)
    enum  = cls && (prop[:type] < EnumType)
    model = cls && (prop[:type] < Model)
    multi = true?(prop[:array])
    delta = {}
    delta[:type]  = 'textarea' if lines&.many? && !cls
    delta[:array] = true       if cls && !prop[:array]
    prop = prop.merge(delta)   if delta.present?

    # Special for ManifestItem
    error   = opt.delete(:field_error)&.dig(field.to_s)&.presence
    err_val = error&.keys&.then { |err| err.many? ? err : err.first }

    # Pre-process value(s).
    if no_format
      value = err_val if err_val && !value.is_a?(Array)
      value = safe_join(value, (separator || "\n")) if value.is_a?(Array)
    elsif prop[:array]
      case value
        when Array  then value = value.dup
        when String then value = value.split("\n")
        else             value = [value]
      end
      value.map!.with_index(1) do |v, i|
        v_opt = { class: "item item-#{i}" }
        append_css!(v_opt, 'error') if error&.key?(v.to_s)
        html_div(v, v_opt)
      end
      value = safe_join(value, (separator || "\n"))
    else
      value = err_val if err_val && !value.is_a?(Array)
      value = safe_join(value, (separator || HTML_BREAK)) if value.is_a?(Array)
    end

    # Extract attributes that are appropriate for the wrapper element which
    # should not propagate into the label, value, or other enclosed elements.
    role = opt.delete(:role)
    lvl  = opt.delete(:'aria-level')
    col  = opt.delete(:'aria-colindex')

    # Add tooltip if configured.
    tooltip = (prop[:tooltip] unless field == :dc_title)

    # Option settings for both label and value.
    status = []
    unless field == :dc_title
      if prop[:array]
        status << 'array'
        status << 'multi' if multi
      else
        case prop[:type]
          when 'textarea' then status << 'textbox'
          when 'number'   then status << 'numeric'
          when 'json'     then status << 'hierarchy'
          else                 status << prop[:type] unless cls
        end
      end
      status << 'enum'  if enum
      status << 'model' if model
    end
    prepend_css!(opt, type, *status)
    prepend_css!(opt, "row-#{row}") if row

    # Explicit 'data-*' attributes.
    opt.merge!(prop.select { |k, _| k.start_with?('data-') })
    opt[:'data-field'] ||= field
    parts = []

    # Label and label HTML options.
    if no_label || label.blank?
      l_id = nil
    else
      # Wrap label text in a <span>.
      unless label.is_a?(ActiveSupport::SafeBuffer)
        label ||= labelize(field)
        label = html_span(label, class: 'text')
      end
      # Append a help icon control if applicable.
      unless no_help || (help = Array.wrap(prop[:help])).blank?
        # NOTE: To accommodate ACE items, an assumption is being made that this
        #   method is only ever called for the decorator's object (and not for
        #   an arbitrary label/value pair outside of that context).
        if field == :emma_retrievalLink
          url   = extract_url(value)
          topic = repository_for(object, url)
          help  = help.many? ? [*help[0...-1], topic] : [*help, topic] if topic
        end
        label += h.help_popup(*help)
      end
      l_tag   = wrap ? :div : tag
      l_id  ||= field_html_id(DEFAULT_LABEL_CLASS, **id_opt)
      l_opt   = prepend_css(opt, label_css)
      l_opt[:id]    = l_id    if l_id
      l_opt[:title] = tooltip if tooltip && !wrap
      parts << html_tag(l_tag, label, l_opt)
    end

    # Value and value HTML options.
    v_tag = wrap ? :div : tag
    v_opt = prepend_css(opt, value_css)
    v_opt[:id]                 = v_id    if v_id
    v_opt[:title]              = tooltip if tooltip && !wrap
    v_opt[:'aria-describedby'] = l_id    if l_id
    parts << html_tag(v_tag, value, v_opt)

    # Optional additional element(s).
    if block_given?
      b_opt = l_id ? opt.merge('aria-describedby': l_id) : opt
      parts += Array.wrap(yield(field, raw_val, prop, **b_opt))
    end

    # Pair wrapper.
    if wrap
      wrap  = PAIR_WRAPPER if wrap.is_a?(TrueClass)
      w_opt = prepend_css(opt, wrap)
      w_opt[:id]                ||= field_html_id(wrap, **id_opt)
      w_opt[:role]              ||= role
      w_opt[:title]             ||= tooltip
      w_opt[:'aria-level']      ||= lvl
      w_opt[:'aria-colindex']   ||= col
      w_opt[:'aria-labelledby'] ||= l_id  if l_id
      append_css!(w_opt, 'error')         if error
      html_tag(tag, *parts, w_opt)
    else
      safe_join(parts)
    end
  end

  # Displayed in place of a results list. # TODO: I18n
  #
  # @type [String]
  #
  NO_RESULTS = 'NONE FOUND'

  # An indicator that can be used to stand for an empty list.
  #
  # @param [String, nil] message      Default: #NO_RESULTS.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_empty_value(message = nil, **)
    render_pair(nil, (message || NO_RESULTS), index: hex_rand)
  end

  # Transform a field value for HTML rendering.
  #
  # @param [*]         value
  # @param [Symbol, *] field
  # @param [Hash]      opt            Passed to #access.
  #
  # @return [Any]                     HTML or scalar value.
  # @return [nil]                     If *value* or *object* is *nil*.
  #
  def render_value(value, field:, **opt)
    value = access(nil, field, opt) if value.nil? && field.is_a?(Symbol)
    value = value.to_s              if value.is_a?(FalseClass)
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
  DEBUG_DECORATOR_EXECUTE = true?(ENV['DEBUG_DECORATOR_EXECUTE'])

  # Attempt to interpret *method* as an *item* method or as a method defined
  # in the current context.
  #
  # @param [Model, Hash, nil] item    Default: `#object`.
  # @param [Symbol]           m
  # @param [Hash, nil]        opt     Options (used only if appropriate).
  #
  # @return [Any]                     HTML or scalar value.
  # @return [nil]                     If executed method returned *nil*.
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def access(item, m, opt = nil)
    item ||= object
    if item.try(:emma_metadata)&.key?(m)
      item.emma_metadata[m]
    elsif item.respond_to?(:fields) && item.include?(m)
      item.fields[m]
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
      args = args.presence
      kw   = (kw.presence if opt.present?)
      if args && kw
        send(m, item, **opt)
      elsif args
        send(m, item)
      elsif kw
        send(m, **opt)
      else
        send(m)
      end
    elsif DEBUG_DECORATOR_EXECUTE
      Log.warn("#{self.class}.access(#{item.class}): #{m.inspect} not usable")
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options for #model_field_values.
  #
  # @type [Array<Symbol>]
  #
  FIELD_VALUES_OPT = %i[columns filter].freeze

  # Specified field selections from the given model instance.
  #
  # @param [Model, Hash, nil]                   item
  # @param [String, Symbol, Array, nil]         columns
  # @param [String, Symbol, Regexp, Array, nil] filter
  #
  # @return [Hash{Symbol=>*}]
  #
  # @see #FIELD_VALUES_OPT
  #
  def model_field_values(item = nil, columns: nil, filter: nil, **)
    item ||= (object if present?)
    pairs  = item.is_a?(Model) ? item.attributes : item
    pairs  = pairs.stringify_keys if pairs.is_a?(Hash)
    return {} if pairs.blank?
    columns &&= Array.wrap(columns).map(&:to_s).compact_blank
    pairs.slice!(*columns) unless columns.blank? || (columns == %w[all])
    Array.wrap(filter).each do |pattern|
      case pattern
        when Regexp then pairs.reject! { |f, _| f.match?(pattern) }
        when Symbol then pairs.reject! { |f, _| f.casecmp?(pattern.to_s) }
        else             pairs.reject! { |f, _| f.downcase.include?(pattern) }
      end
    end
    cfg = model_context_fields || model_index_fields
    pairs.transform_keys!(&:to_sym).delete_if { |f, _| cfg.dig(f, :ignored) }
  end

  # Render a metadata listing of a model instance.
  #
  # @param [Hash, nil]   pairs        Label/value pairs.
  # @param [Hash]        outer        HTML options for outer div.
  # @param [String, nil] css          Default: "#(model_type)-details"
  # @param [Hash]        opt          Passed to #render_field_values except:
  #
  # @option opt [String] :class       Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details(pairs: nil, outer: nil, css: nil, **opt)
    fv_opt   = opt.extract!(*FIELD_VALUES_OPT)
    pairs  ||= model_field_values(**fv_opt)
    count    = pairs.size
    css    ||= "#{model_type}-details"
    classes  = [css, opt.delete(:class)]
    classes << "columns-#{count}" if count.positive?
    html_div(prepend_css(outer, *classes)) do
      render_field_values(pairs: pairs, **opt)
    end
  end

  # details_container
  #
  # @param [Array]               added  Optional elements after the details.
  # @param [Integer, nil]        level
  # @param [String, Symbol, nil] role
  # @param [String, nil]         css    Default: "#(model_type)-container"
  # @param [Hash]                opt    Passed to #details.
  # @param [Proc, nil]           block  Passed to #capture.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_container(*added, level: nil, role: nil, css: nil, **opt, &block)
    css  ||= ".#{model_type}-container"
    role ||= (:article if level == 1)
    opt.delete(:skip) # In case this slipped in to the base method.

    parts = [details(**opt), *added]
    parts << h.capture(&block) if block

    outer_opt = { role: role }.compact
    prepend_css!(outer_opt, css)
    html_div(*parts, outer_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A complete list item entry.
  #
  # @param [Hash, nil]     add        Additional label/value pairs.
  # @param [Array<Symbol>] skip       Display aspects to avoid.
  # @param [Hash]          opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_row(add: nil, skip: [], **opt)
    opt[:id] ||= model_item_id
    l     = opt.delete(:level)
    skip  = Array.wrap(skip)
    parts = []
    parts << list_item_number(level: l, **opt) unless skip.include?(:number)
    parts << thumbnail(link: true, **opt)      unless skip.include?(:thumbnail)
    parts << list_item(pairs: add, **opt)
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
  #--
  # noinspection RailsParamDefResolve
  #++
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

    # Set up number label and inner parts if supplied.
    inner_parts = []
    inner_parts << list_item_number_label(index: index)
    inner_parts += inner if inner.is_a?(Array)
    inner_parts << inner if inner.is_a?(String)

    # Set up outer parts if supplied.
    outer_parts = []
    outer_parts += outer if outer.is_a?(Array)
    outer_parts << outer if outer.is_a?(String)

    # Additional elements supplied by the block:
    if block_given? && (added = Array.wrap(yield)).present?
      if inner.is_a?(TrueClass) || outer.nil? || outer.is_a?(FalseClass)
        inner_parts += added
      else
        outer_parts += added
      end
    end

    # Wrap parts in a container for group positioning:
    inner_opt = prepend_css(opt, 'container')
    inner_opt[:id] &&= "#{inner_opt[:id]}-container"
    container = html_tag(level, inner_parts, inner_opt)

    # Wrap the container in the actual number grid element.
    outer_opt = append_css(opt.slice(:id), css)
    outer_opt[:id] &&= "#{outer_opt[:id]}-number"
    append_css!(outer_opt, 'empty')      if blank?
    append_css!(outer_opt, "row-#{row}") if row
    outer_opt[:'data-group']    = group  if group
    outer_opt[:'data-title_id'] = object.try(:emma_titleId)
    html_div(container, outer_parts, outer_opt)
  end

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

    # Label visible only to screen-readers:
    l_opt   = prepend_css(opt, 'sr-only')
    label ||= index ? 'Entry ' : 'Empty results' # TODO: I18n
    label   = html_span(label, l_opt)

    # Visible item number value:
    v_opt   = prepend_css(opt, 'value')
    value ||= index ? "#{index + 1}" : ''
    value   = html_span(value, v_opt)

    # noinspection RubyMismatchedReturnType
    label << value
  end

  # Render a single entry for use within a list of items.
  #
  # @param [Hash, nil]     pairs      Label/value pairs.
  # @param [Symbol]        render     Default: #render_field_values.
  # @param [Hash]          outer      HTML options for outer div container.
  # @param [String, Array] leading    Optional leading column(s).
  # @param [String, Array] trailing   Optional trailing columns(s).
  # @param [Symbol]        tag        If :tr, generate <tr>.
  # @param [Integer, nil]  level
  # @param [String]        css        Default: .(model_type)-list-item
  # @param [String]        id         Passed to :outer div.
  # @param [Hash]          opt        Passed to the render method.
  #
  # @option opt [Integer] :row        Sets "row-#{row}" in :outer div.
  # @option opt [Symbol]  :group      May set :'data-group' for :outer div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(
    pairs:    nil,
    render:   nil,
    outer:    nil,
    leading:  nil,
    trailing: nil,
    tag:      :div,
    level:    nil,
    css:      nil,
    id:       nil,
    **opt
  )
    css   ||= ".#{model_type}-list-item"
    row     = positive(opt[:row])
    role    = opt.delete(:role)
    group   = opt[:group] ||= state_group
    row_opt = prepend_css(outer, css)
    row_opt[:id]              ||= id   || model_item_id(**opt)
    row_opt[:role]            ||= role || ('heading' if level)
    row_opt[:'data-group']    ||= group
    row_opt[:'data-title_id'] ||= title_id_values
    row_opt[:'aria-level']    ||= level
    row_opt.delete(:'aria-rowindex')   unless for_html_table?(tag)
    row_opt.delete(:'aria-colindex')
    append_css!(row_opt, "row-#{row}") if row
    append_css!(row_opt, 'empty')      if blank?
    html_tag(tag, row_opt) do
      leading  &&= Array.wrap(leading).compact.map  { |v| ERB::Util.h(v) }
      trailing &&= Array.wrap(trailing).compact.map { |v| ERB::Util.h(v) }
      render = :render_empty_value  if blank?
      render = :render_field_values if render.nil?
      pairs  = send(render, pairs: pairs, **opt, level: level&.next)
      [*leading, *pairs, *trailing]
    end
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
  #--
  # noinspection RubyAssignmentExpressionInConditionalInspection
  #++
  def thumbnail(link: false, placeholder: true, css: '.thumbnail', **opt)
    ph       = placeholder.presence
    html_opt = remainder_hash!(opt, :meth, :alt, *ITEM_ENTRY_OPT)
    prepend_css!(html_opt, css)
    if (url = get_thumbnail_image(**opt))
      id   = object.identifier
      link = show_path(id: id) if link.is_a?(TrueClass)
      link = nil               if link.is_a?(FalseClass)
      alt  = opt[:alt] || config_lookup('thumbnail.image.alt', item: id)
      row  = positive(opt[:row])
      html_opt[:id] = "container-img-#{id}"
      html_opt[:'data-group'] = opt[:group] if opt[:group].present?
      html_opt[:'data-turbolinks-permanent'] = true
      # noinspection RubyMismatchedArgumentType
      image_element(url, link: link, alt: alt, row: row, **html_opt)
    end ||
      (ph && placeholder_element(comment: 'no thumbnail', **html_opt))
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
  #--
  # noinspection RubyAssignmentExpressionInConditionalInspection
  #++
  def cover(link: false, placeholder: true, css: '.cover-image', **opt)
    ph       = placeholder.presence
    html_opt = remainder_hash!(opt, :meth, :alt, *ITEM_ENTRY_OPT)
    prepend_css!(html_opt, css)
    html_opt[:'data-group'] = opt[:group] if opt[:group].present?
    if (url = get_cover_image(**opt))
      id   = object.identifier
      link = show_path(id: id) if link.is_a?(TrueClass)
      link = nil               if link.is_a?(FalseClass)
      alt  = opt[:alt] || config_lookup('cover.image.alt', item: id)
      row  = positive(opt[:row])
      # noinspection RubyMismatchedArgumentType
      image_element(url, link: link, alt: alt, row: row, **html_opt)
    end ||
      (ph && placeholder_element(comment: 'no cover image', **html_opt))
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
  #--
  # noinspection RailsParamDefResolve
  #++
  def model_item_id(**opt)
    obj = (object if present?)
    id  = obj&.try(:submission_id) || obj&.try(:identifier) || hex_rand
    html_id(model_type, id, underscore: false, **opt)
  end

  # All :emma_titleId value(s) associated with the object.
  #
  # @return [String,nil]
  #
  def title_id_values
    # noinspection RailsParamDefResolve
    records = (object.try(:records) if present?)
    records&.map(&:emma_titleId)&.compact&.uniq&.join(',')&.presence
  end

  # state_group
  #
  # @return [Symbol, nil]
  #
  def state_group(...)
    # noinspection RailsParamDefResolve
    (object if present?)&.try(:state_group)
  end

  # get_thumbnail_image
  #
  # @param [Symbol, nil] meth
  #
  # @return [String, nil]
  #
  def get_thumbnail_image(meth: :thumbnail_image, **)
    @thumbnail ||= thumbnail_data
    # noinspection RubyMismatchedArgumentType
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
    # noinspection RubyMismatchedArgumentType
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
