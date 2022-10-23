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

  # The CSS class wrapping label/values pairs (if any).
  #
  # @type [String, nil]
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

    fp_opt      = extract_hash!(opt, *FIELD_PAIRS_OPTIONS)
    value_opt   = opt.slice(:index, :no_format)
    opt[:row]   = 0
    separator ||= DEFAULT_ELEMENT_SEPARATOR

    # noinspection RubyMismatchedArgumentType
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
  # == Implementation Notes
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
  # @param [Any, nil]             value
  # @param [Hash, nil]            prop      Default: from field/model.
  # @param [Symbol, nil]          field
  # @param [String, Integer]      index     Offset to make unique element IDs.
  # @param [Integer, nil]         row       Display row.
  # @param [String, nil]          separator Between parts if *value* is array.
  # @param [String, nil]          wrap      Class for outer wrapper.
  # @param [Symbol]               tag       @see BaseDecorator::Grid#TABLE_TAGS
  # @param [Boolean,Symbol,Array] no_format
  # @param [Boolean]              no_code
  # @param [Boolean]              no_label
  # @param [Boolean]              no_help
  # @param [String, nil]          label_css
  # @param [String, nil]          value_css
  # @param [Hash]                 opt       Passed to each #html_div except:
  #
  # @option opt [String] :role              Passed to outer wrapper only.
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
  # == Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedArgumentType
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
    label_css:  'label',
    value_css:  'value',
    **opt,
    &block
  )
    prop  ||= field_configuration(field)
    field ||= prop[:field]

    # Setup a lambda for creating related HTML identifiers.
    id_base = model_html_id(field || label)
    make_id = ->(v) { html_id(v, id_base, index, underscore: false) }

    # Extract range values.
    value   = value.content if value.is_a?(Field::Type)
    raw_val = value

    # Format the content of certain fields.
    lines     = nil
    no_format = [no_format]               if no_format.is_a?(Symbol)
    no_format = no_format.include?(field) if no_format.is_a?(Array)
    unless no_format
      # noinspection RubyCaseWithoutElseBlockInspection
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
    enum  = prop[:type].is_a?(Class)
    multi = true?(prop[:array])
    delta = {}
    delta[:type]  = 'textarea' if lines&.many? && !enum
    delta[:array] = true       if enum && !multi && !prop[:array]
    prop = prop.merge(delta)   if delta.present?

    # Pre-process value(s).
    if no_format
      value = safe_join(value, separator) if value.is_a?(Array)
    elsif prop[:array]
      value = value.is_a?(Array) ? value.dup : [value]
      value.map!.with_index(1) { |v, i| html_div(v, class: "item item-#{i}") }
      value = safe_join(value, separator)
    elsif value.is_a?(Array)
      value = safe_join(value, (separator || HTML_BREAK))
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
          else                 status << prop[:type] unless enum
        end
      end
      status << 'enum' if enum
    end
    prepend_css!(opt, "row-#{row}") if row
    prepend_css!(opt, "field-#{id_base}", *status)

    # Explicit 'data-*' attributes.
    opt.merge!(prop.select { |k, _| k.start_with?('data-') })
    opt[:'data-field'] ||= field
    parts = []

    # Label and label HTML options.
    l_id = nil
    unless no_label || (label = prop[:label] || label).blank?
      # Wrap label text in a <span>.
      unless label.is_a?(ActiveSupport::SafeBuffer)
        label ||= labelize(field)
        label = html_span(label, class: 'text')
      end
      # Append a help icon control if applicable.
      unless no_help || (help = prop[:help]).blank?
        replace = topic = nil
        if field == :emma_retrievalLink
          url     = extract_url(value)
          topic   = url_repository(url, default: !application_deployed?)
          replace = help.is_a?(Array) && (help.size > 1)
        end
        help = replace ? (help[0...-1] << topic) : [*help, topic] if topic
        label += h.help_popup(*help)
      end
      l_tag = wrap ? :div : tag
      l_id  = make_id.call('label')
      l_opt = prepend_css(opt, label_css)
      l_opt[:id]    = l_id    if l_id
      l_opt[:title] = tooltip if tooltip && !wrap
      parts << html_tag(l_tag, label, l_opt)
    end

    # Value and value HTML options.
    v_tag = wrap ? :div : tag
    v_id  = make_id.call('value')
    v_opt = prepend_css(opt, value_css)
    v_opt[:id]                = v_id    if v_id
    v_opt[:title]             = tooltip if tooltip && !wrap
    v_opt[:'aria-labelledby'] = l_id    if l_id
    parts << html_tag(v_tag, value, v_opt)

    # Optional additional element(s).
    if block_given?
      b_opt = l_id ? opt.merge('aria-labelledby': l_id) : opt
      parts += Array.wrap(yield(field, raw_val, prop, **b_opt))
    end

    # Pair wrapper.
    if wrap
      wrap  = PAIR_WRAPPER if wrap.is_a?(TrueClass)
      w_opt = prepend_css(opt, wrap)
      w_opt.reverse_merge!(
        id:               make_id.call(wrap),
        role:             role,
        title:            tooltip,
        'aria-level':     lvl,
        'aria-colindex':  col,
      )
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
    # noinspection RubyMismatchedReturnType
    render_pair(nil, (message || NO_RESULTS))
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
  # noinspection RubyNilAnalysis, RailsParamDefResolve
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
  # :section: Item details (show page) support
  # ===========================================================================

  public

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
    css    ||= "#{model_type}-details"
    count    = positive(pairs&.size)
    classes  = [css, opt.delete(:class)]
    classes << "columns-#{count}" if count
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
  # @param [Proc]                block  Passed to #capture.
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
  # :section: Item list (index page) support
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
    opt[:id]              ||= model_item_id
    opt[:'aria-rowindex'] ||= opt[:index] + 1 if opt[:index]
    skip  = Array.wrap(skip)
    parts = []
    parts << list_item_number(**opt)      unless skip.include?(:number)
    parts << thumbnail(link: true, **opt) unless skip.include?(:thumbnail)
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
    container = html_tag(level, inner_parts, inner_opt)

    # Wrap the container in the actual number grid element.
    outer_opt = append_css(css)
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
  # @option opt [Integer] :index      May set :'aria-rowindex' for :outer div.
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
    group   = opt[:group] ||= state_group
    role    = opt.delete(:role) || ('heading' if level)
    classes = [css] << ("row-#{row}" if row) << ('empty' if blank?)
    row_opt = prepend_css(outer, *classes).except!(:'aria-colindex')
    row_opt.reverse_merge!(
      id:               id || model_item_id(**opt),
      role:             role,
      'data-group':     group,
      'data-title_id':  title_id_values,
      'aria-level':     level,
      'aria-rowindex':  opt[:index]&.next,
    )
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
  # :section: Item list (index page) support
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
