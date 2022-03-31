# app/decorators/base_decorator/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting display of individual Model instances.
#
module BaseDecorator::List

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
  # @param [Hash, nil]           pairs        Passed to #field_pairs.
  # @param [String, Symbol, nil] action       Passed to #field_pairs.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field_values(
    pairs:      nil,
    action:     nil,
    row_offset: nil,
    field_root: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    **opt
  )
    return ''.html_safe if pairs.nil? && object.nil?

    opt[:row] = row_offset || 0
    value_opt = opt.slice(:index, :min_index, :max_index, :no_format)
    fp_opt    = { action: action, field_root: field_root }

    # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
    field_pairs(pairs, **fp_opt).map { |field, prop|
      opt[:row] += 1
      value  = render_value(prop[:value], field: field, **value_opt)
      scopes = field_scopes(field).presence
      rp_opt = scopes ? append_css(opt, scopes) : opt
      render_pair(prop[:label], value, prop: prop, **rp_opt)
    }.unshift(nil).join(separator).html_safe
  end

  # Render a single label/value pair.
  #
  # @param [String, Symbol, nil] label
  # @param [Any, nil]            value
  # @param [Hash, nil]           prop       Default: from field/model.
  # @param [Symbol, nil]         field
  # @param [String, Integer]     index      Offset to make unique element IDs.
  # @param [Integer, nil]        row        Display row.
  # @param [String, nil]         separator  Between parts if *value* is array.
  # @param [String, nil]         wrap       Class for outer wrapper.
  # @param [Hash]                opt        Passed to each #html_div except:
  #
  # @option opt [Symbol, Array<Symbol>] :no_format
  # @option opt [Boolean]               :no_code
  #
  # @return [ActiveSupport::SafeBuffer]     HTML label and value elements.
  # @return [nil]                           If *value* is blank.
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
    prop:      nil,
    field:     nil,
    index:     nil,
    row:       1,
    separator: nil,
    wrap:      nil,
    **opt
  )
    return if value.blank?
    prop  ||= field_configuration(field)
    field ||= prop[:field]

    # Pre-process label to derive names and identifiers.
    base = model_html_id(field || label)
    v_id = ['value', base, index].compact.join('-')
    l_id = ['label', base, index].compact.join('-')

    # Extract range values.
    value = value.content if value.is_a?(Field::Type)

    # Format the content of certain fields.
    no_code = opt.delete(:no_code)
    lines   = nil
    unless Array.wrap(opt.delete(:no_format)).include?(field)
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
    delta = {}
    delta[:type]  = 'textarea' if lines&.many? && !enum
    delta[:array] = true       if enum && !prop[:array]
    prop = prop.merge(delta)   if delta.present?

    # Pre-process value(s).
    if prop[:array]
      value = value.is_a?(Array) ? value.dup : [value]
      value.map!.with_index(1) { |v, i| html_div(v, class: "item-#{i}") }
      value = safe_join(value, separator)
    elsif value.is_a?(Array)
      value = safe_join(value, (separator || HTML_BREAK))
    end

    # Create a help icon control if applicable.
    if (help = prop[:help]).present?
      replace = topic = nil
      if field == :emma_retrievalLink
        url     = extract_url(value)
        topic   = url_repository(url, default: !application_deployed?)
        replace = help.is_a?(Array) && (help.size > 1)
      end
      help = replace ? (help[0...-1] << topic) : [*help, topic] if topic
      help = h.help_popup(*help)
    end

    # Add tooltip if configured.
    tooltip = (prop[:tooltip] unless field == :dc_title)

    # Option settings for both label and value.
    status = nil
    unless field == :dc_title
      status ||= ('array'     if prop[:array] && enum)
      status ||= ('list'      if prop[:array])
      status ||= ('enum'      if enum)
      status ||= ('textbox'   if prop[:type] == 'textarea')
      status ||= ('numeric'   if prop[:type] == 'number')
      status ||= ('hierarchy' if prop[:type] == 'json')
      status ||= prop[:type]
    end
    prepend_css!(opt, "field-#{base}", status, "row-#{row}")

    # Explicit 'data-*' attributes.
    opt.merge!(prop.select { |k, _| k.start_with?('data-') })

    # Label and label HTML options.
    l_opt = prepend_css(opt, 'label')
    l_opt[:id]    = l_id    if l_id
    l_opt[:title] = tooltip if tooltip && !wrap
    label = prop[:label] || label
    unless label.is_a?(ActiveSupport::SafeBuffer)
      label ||= labelize(field)
      label = html_span(label, class: 'text')
    end
    label += help if help.present?
    label = html_div(label, l_opt)

    # Value and value HTML options.
    v_opt = prepend_css(opt, 'value')
    v_opt[:id]                = v_id    if v_id
    v_opt[:title]             = tooltip if tooltip && !wrap
    v_opt[:'aria-labelledby'] = l_id    if l_id
    value = html_div(value, v_opt)

    # Pair wrapper.
    if wrap
      wrap  = 'pair' if wrap.is_a?(TrueClass)
      w_opt = prepend_css(opt, wrap)
      w_opt[:id]    = [wrap, base, index].compact.join('-')
      w_opt[:title] = tooltip if tooltip
      html_div(w_opt) { label << value }
    else
      # noinspection RubyMismatchedReturnType
      label << value
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
  # @param [Any]       value
  # @param [Symbol, *] field
  # @param [Hash]      opt            Passed to #execute.
  #
  # @return [Any]                     HTML or scalar value.
  # @return [nil]                     If *value* or *object* is *nil*.
  #
  def render_value(value, field:, **opt)
    value = execute(nil, field, **opt) if value.nil? && field.is_a?(Symbol)
    value = value.to_s                 if value.is_a?(FalseClass)
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
  def execute(item, m, opt = nil)
    item ||= object
    if item.try(:emma_metadata)&.key?(m)
      item.emma_metadata[m]
    elsif item.respond_to?(:fields) && item.include?(m)
      item.fields[m]
    elsif item.try(:key?, m)
      item[m]
    elsif item.respond_to?(m)
      kw = opt.present?
      if kw && item.method(m).parameters.any? { |k, _| k.start_with?('key') }
        item.send(m, **opt)
      else
        item.send(m)
      end
    elsif respond_to?(m)
      prm = method(m).parameters
      kw, args = prm.partition { |p, _| p.start_with?('key') }.map!(&:presence)
      kw &&= false if opt.blank?
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
      Log.warn("#{self.class}.execute(#{item.class}): #{m.inspect} not usable")
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of a model instance.
  #
  # @param [Hash, nil] pairs          Label/value pairs.
  # @param [Hash]      opt            Passed to #render_field_values except:
  #
  # @option opt [String] :class       Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details(pairs: nil, **opt)
    outer_classes = css_classes("#{model_type}-details", opt.delete(:class))
    html_div(class: outer_classes) do
      render_field_values(pairs: pairs, **opt)
    end
  end

  # details_element
  #
  # @param [Integer, nil]        level
  # @param [String, Symbol, nil] role
  # @param [Hash]                opt    Passed to #details.
  # @param [Proc]                block  Passed to #html_join.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_element(level: nil, role: nil, **opt, &block)
    role ||= (:article if level == 1)
    added  = block ? h.capture(&block) : ''
    html_div(class: "#{model_type}-container", role: role) do
      details(**opt) << added
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # A complete list item entry.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_row(**opt)
    opt[:id] ||= model_item_id
    skip  = Array.wrap(opt.delete(:skip))
    add   = opt.delete(:add)
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
  ITEM_ENTRY_OPT = %i[index offset group row level skip].freeze

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
  # @param [Integer, nil]           offset  Default: 0.
  # @param [Integer, nil]           level   Heading tag level (@see #html_tag).
  # @param [String, nil]            group   Sets :'data-group' for outer div.
  # @param [Integer, nil]           row
  # @param [Boolean, String, Array] inner   *1* above.
  # @param [Boolean, String, Array] outer   *2* above.
  # @param [Hash]                   opt     Passed to inner #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield [index,offset] To supply additional parts within .number element.
  # @yieldparam  [Integer] index      The effective index number.
  # @yieldparam  [Integer] offset     The effective page offset.
  # @yieldreturn [Array<ActiveSupport::SafeBuffer>]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def list_item_number(
    index:,
    offset: nil,
    level:  nil,
    group:  nil,
    row:    nil,
    inner:  nil,
    outer:  nil,
    **opt
  )
    css    = '.number'
    index  = non_negative(index) or return
    row    = positive(row)
    offset = positive(offset) || 0

    opt.except!(*ITEM_ENTRY_OPT)

    # Set up outer parts if supplied.
    inner_parts = []
    outer_parts = []
    if outer.is_a?(Array) || outer.is_a?(String)
      outer_parts += Array.wrap(outer)
    end

    # Label visible only to screen-readers:
    label = index ? 'Entry ' : 'Empty results' # TODO: I18n
    inner_parts << html_span(label, class: 'sr-only')

    # Visible item number value:
    value = index ? "#{offset + index + 1}" : ''
    inner_parts << html_span(value, class: 'value')

    # Add inner parts if supplied.
    if inner.is_a?(Array) || inner.is_a?(String)
      inner_parts += Array.wrap(inner)
    end

    # Additional elements supplied by the block:
    # noinspection RubyMismatchedArgumentType
    if block_given? && (added = Array.wrap(yield(index, offset))).present?
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

  # Render a single entry for use within a list of items.
  #
  # @param [Hash, nil] pairs          Label/value pairs.
  # @param [Symbol]    render         Default: #render_field_values.
  # @param [Hash]      opt            Passed to the render method.
  #
  # @option opt [Hash] :outer         HTML options for outer div container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(pairs: nil, render: nil, **opt)
    css = ".#{model_type}-list-item"
    row = positive(opt[:row])
    html_opt = {
      id:              opt.delete(:id) || model_item_id(**opt),
      'data-group':    (opt[:group] ||= state_group),
      'data-title_id': title_id_values,
    }.merge!(opt.delete(:outer) || {})
    prepend_css!(html_opt, 'empty')      if blank?
    prepend_css!(html_opt, "row-#{row}") if row
    prepend_css!(html_opt, css)
    html_div(html_opt) do
      render = :render_empty_value  if blank?
      render = :render_field_values if render.nil?
      send(render, pairs: pairs, **opt)
    end
  end

  # Thumbnail element for the given catalog title.
  #
  # @param [Boolean, String] link         If *true* make the image a link to
  #                                         the show page for the item.
  # @param [Boolean]         placeholder  If *false*, return *nil* if an image
  #                                         could not be determined.
  # @param [Hash]            opt          To ImageHelper#image_element except:
  #
  # @option opt [Symbol] :meth            Passed to #get_thumbnail_image
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyAssignmentExpressionInConditionalInspection
  #++
  def thumbnail(link: false, placeholder: true, **opt)
    css      = '.thumbnail'
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
  # @param [Hash]            opt          To ImageHelper#image_element except:
  #
  # @option opt [Symbol] :meth            Passed to #get_cover_image
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyAssignmentExpressionInConditionalInspection
  #++
  def cover(link: false, placeholder: true, **opt)
    css      = '.cover-image'
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
  # @return [String]
  #
  #--
  # noinspection RailsParamDefResolve
  #++
  def model_item_id(...)
    obj = (object if present?)
    id  = obj&.try(:submission_id) || obj&.try(:identifier) || hex_rand
    html_id(model_type, id, underscore: false)
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
