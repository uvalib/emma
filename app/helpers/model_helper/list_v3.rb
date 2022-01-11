# app/helpers/model_helper/list_v3.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display and creation of Model instances
# (both database items and API messages).
#
module ModelHelper::ListV3

  include ModelHelper::List

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render field/value pairs of a title-level record.
  #
  # @param [Search::Record::TitleRecord, nil] item
  # @param [String, Symbol, nil] model        Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: `params[:action]`.
  # @param [Hash, nil]           pairs        Except for #render_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedArgumentType
  #++
  def render_field_hierarchy(
    item,
    model:      nil,
    action:     nil,
    pairs:      nil,
    row_offset: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    **opt
  )
    return ''.html_safe unless item

    opt[:row]    = row_offset || 0
    opt[:model]  = Model.for(model || item) || params[:controller]&.to_sym
    opt[:action] = action

    # Get the hierarchy of field/value pairs, inserting additional field/value
    # pairs (if any) at the title level.
    hierarchy = item.field_hierarchy
    if pairs.present?
      hierarchy = hierarchy.dup
      pairs =
        pairs.reject do |k, v|
          hierarchy[k] = v if v.is_a?(Hash) || v.is_a?(Array)
        end
      hierarchy.reverse_merge!(nil => { nil => pairs }) if pairs.present?
    end

    # Get a line for each metadata field/pair and plus interstitial content.
    lines = item_lines(item, hierarchy, opt)
    # noinspection RubyMismatchedReturnType
    lines.map! { |v| v.is_a?(Hash) ? render_field(v, opt) : ERB::Util.h(v) }
    lines.compact!
    lines.unshift(nil).join(separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The term used for a file instance instead of 'file'. # TODO: I18n
  #
  # @type [String, nil]
  #
  FILE_TERM = 'copy'

  # item_lines
  #
  # @param [Search::Record::TitleRecord] item
  # @param [Hash, nil]                   hierarchy
  # @param [Hash]                        opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  def item_lines(item, hierarchy, opt)
    opt[:record_map] ||= item.records.map { |r| [r.emma_recordId, r] }.to_h
    item_index = [opt[:index]]
    item_prop  = { record: item }
    skip_opt   = { meth: __method__, except: { hash: :title, array: :parts } }
    (hierarchy || item.field_hierarchy).flat_map { |main_key, main_section|
      next if skip_entry?(main_key, main_section, **skip_opt)
      main_index = item_index
      main_prop  = add_scope(item_prop, main_key)
      if main_key == :title
        title_level_lines(main_section, main_index, main_prop, opt)
      else
        part_level_lines(main_section, main_index, main_prop, opt)
      end
    }.compact_blank!
  end

  # title_level_lines
  #
  # @param [Hash]  main_section
  # @param [Array] main_index
  # @param [Hash]  main_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  def title_level_lines(main_section, main_index, main_prop, opt)
    file_section_lines(main_section, main_index, main_prop, opt)
  end

  # part_level_lines
  #
  # @param [Array<Hash>] main_section
  # @param [Array]       main_index
  # @param [Hash]        main_prop
  # @param [Hash]        opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  def part_level_lines(main_section, main_index, main_prop, opt)
    multiple_parts = main_section.many?
    main_section.flat_map.with_index(1) do |part, part_no|
      index = [*main_index, part_no]
      prop  = main_prop.merge('data-part': part_no)

      # Defer the heading row until the enclosed information is gathered.
      h_row = opt[:row]
      opt[:row] += 1
      lines = part_section_lines(part, index, prop, opt)

      # Create the heading row.
      value   = part.dig(:bibliographic, :bib_seriesPosition).presence
      if multiple_parts && !value
        value = :all
        name  = ERB::Util.h('Complete Work') # TODO: I18n
      else
        name  = value&.inspect || part_no
      end
      details = count_unique(lines, :format)
      h_opt   = opt.merge(row: h_row)
      heading = new_section(:part, name, value, details, index, prop, h_opt)

      [heading, *lines]
    end
  end

  # part_section_lines
  #
  # @param [Hash]  part
  # @param [Array] part_index
  # @param [Hash]  part_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  def part_section_lines(part, part_index, part_prop, opt)
    skip_opt = { meth: __method__, except: { array: :formats } }
    part.flat_map { |part_key, part_section|
      next if part_key == :bibliographic
      next if skip_entry?(part_key, part_section, **skip_opt)
      part_lines(part_section, part_key, part_index, part_prop, opt)
    }.compact_blank!
  end

  # part_level_lines
  #
  # @param [Array<Hash>] part_section
  # @param [Symbol]      part_key
  # @param [Array]       part_index
  # @param [Hash]        part_prop
  # @param [Hash]        opt
  #
  # @option opt [String] :term        Override #FILE_TERM.
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  def part_lines(part_section, part_key, part_index, part_prop, opt)
    opt[:term] ||= FILE_TERM
    part_section.flat_map.with_index(1) do |format, format_no|
      index = [*part_index, format_no]
      prop  = add_scope(part_prop, part_key, index: index)
      prop[:'data-format'] = format_no

      # Defer the heading row until the enclosed information is gathered.
      h_row = opt[:row]
      opt[:row] += 1
      lines = format_section_lines(format, index, prop, opt)

      # Create the heading row.
      value   = format.dig(:bibliographic, :dc_format).presence
      name    = value ? ERB::Util.h(value.titleize.upcase) : format_no
      details = count_unique(lines, :file, term: opt[:term])
      h_opt   = opt.merge(row: h_row)
      heading = new_section(:format, name, value, details, index, prop, h_opt)

      [heading, *lines]
    end
  end

  # format_section_lines
  #
  # @param [Hash]  format
  # @param [Array] format_index
  # @param [Hash]  format_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  def format_section_lines(format, format_index, format_prop, opt)
    skip_opt = { meth: __method__, except: { array: :files } }
    format.flat_map { |fmt_key, fmt_entry|
      next if fmt_key == :bibliographic
      next if skip_entry?(fmt_key, fmt_entry, **skip_opt)
      file_lines(fmt_entry, fmt_key, format_index, format_prop, opt)
    }.compact_blank!
  end

  # part_level_lines
  #
  # @param [Array<Hash>] files
  # @param [Symbol]      section_key
  # @param [Array]       section_index
  # @param [Hash]        section_prop
  # @param [Hash]        opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  def file_lines(files, section_key, section_index, section_prop, opt)
    record_map = opt[:record_map]
    files.flat_map.with_index(1) do |file, file_no|
      rec     = record_map[file.dig(:index, :emma_recordId)]
      index   = [*section_index, file_no]
      prop    = add_scope(section_prop, section_key, index: index, record: rec)
      prop[:'data-file'] = file_no
      value   = (file_no if files.many?)
      name    = file_no
      heading = new_section(:file, name, value, nil, index, prop, opt)
      lines   = file_section_lines(file, index, prop, opt)
      [heading, *lines]
    end
  end

  # file_section_lines
  #
  # @param [Hash]  section
  # @param [Array] section_index
  # @param [Hash]  section_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash>]
  #
  def file_section_lines(section, section_index, section_prop, opt)
    skip_opt = { meth: __method__, except: { hash: '*' } }
    section.flat_map { |section_key, section_entry|
      next if skip_entry?(section_key, section_entry, **skip_opt)
      prop = add_scope(section_prop, section_key, index: section_index)
      field_lines(section_entry, prop, opt)
    }.compact_blank!
  end

  # field_lines
  #
  # @param [Hash] pairs
  # @param [Hash] field_prop
  # @param [Hash] opt
  #
  # @return [Array<Hash>]
  #
  def field_lines(pairs, field_prop, opt)
    fp_opt = opt.slice(:model, :action)
    field_pairs(nil, **fp_opt, pairs: pairs).map { |_field, prop|
      prop.merge(field_prop, row: (opt[:row] += 1))
    }.compact_blank!
  end

  # render_field
  #
  # @param [Hash] line
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def render_field(line, opt)
    opt         = opt.except(:action, :record_map)
    value_opt   = opt.slice(:model, :index, :min_index, :max_index, :no_format)
    label, record, field = line.values_at(:label, :record, :field)
    value       = render_value(record, line[:value], field: field, **value_opt)
    opt[:row]   = line[:row]
    opt[:index] = Array.wrap(line[:index]).compact.join('-')
    scopes      = field_scopes(line[:scopes])
    append_classes!(opt, scopes) if scopes.present?
    render_line(label, value, prop: line, **opt)
  end

  # The CSS class wrapping label/values pairs (if any).
  #
  # @type [String, nil]
  #
  PAIR_WRAPPER = 'pair'

  # Divider between metadata for individual sections within a compound search
  # item.
  #
  # @note SIDE EFFECT: `opt[:row]` will be incremented.
  #
  # @param [Symbol, String] type
  # @param [Any]            name        Distinct section indicator.
  # @param [Any, nil]       data_value  For 'data-value'.
  # @param [Any, nil]       details
  # @param [Any]            index       Unique line indicator.
  # @param [Hash]           prop
  # @param [Hash]           opt         Passed to #render_line.
  #
  # @option opt [String] :term          Override #FILE_TERM.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def new_section(type, name, data_value, details, index, prop, opt)
    css_selector = '.field-section'
    opt[:row] += 1
    open   = true
    type   = type.to_s
    field  = :"new_#{type.underscore}"
    base   = model_html_id(field)
    index  = index.compact.join('-') if index.is_a?(Array)

    # The open/close toggle control for this section.
    tgt_id = [(PAIR_WRAPPER || 'value'), base, index].compact.join('-')
    toggle = search_list_item_toggle(id: tgt_id, context: type, open: open)

    # Prepend the toggle control to the label.
    if name.is_a?(ActiveSupport::SafeBuffer)
      label = name
    else
      term  = opt[:term] || FILE_TERM || type
      label = html_span("#{term.titleize} #{name}", class: 'text')
    end
    label = toggle << label

    # Make an non-empty value portion.
    value  = details || HTML_SPACE
    value  = html_span(value, class: 'details')

    opt = prepend_classes(opt, css_selector, ('open' if open))
    opt.merge!(index: index, field: field, 'data-value': data_value)
    opt.merge!(prop.select { |k, _| k.start_with?('data-') })
    render_line(label, value, **opt)
  end

  # Render a single label/value line.
  #
  # @param [String, Symbol, nil] label
  # @param [Any, nil]            value
  # @param [Hash]                opt        Passed #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_line(label, value, **opt)
    opt[:wrap] ||= PAIR_WRAPPER
    render_pair(label, value, **opt) || ''.html_safe
  end

  # skip_entry?
  #
  # @param [Symbol]              key
  # @param [Any]                 value
  # @param [Symbol]              meth
  # @param [Hash, Array, Symbol] except
  #
  def skip_entry?(key, value, meth: nil, except: nil, **)
    return true if key.start_with?('_')
    ok = { hash: [], array: [] }
    if except.is_a?(Hash)
      # noinspection RubyMismatchedArgumentType
      ok.merge!(except)
    elsif except
      # noinspection RubyMismatchedReturnType
      ok.transform_values! { except }
    end
    ok.transform_values! { |v| Array.wrap(v).compact }
    ok.transform_values! { |v| v.include?('*') ? [key] : v.map!(&:to_sym) }
    error =
      case value
        when Hash  then 'unexpected section' unless ok[:hash].include?(key)
        when Array then 'unexpected array'   unless ok[:array].include?(key)
        else            "unexpected value (#{value.inspect})"
      end
    error ||= ('empty' if value.blank?)
    Log.debug { "#{meth || __method__}: #{key}: #{error}" } if error
    error.present?
  end

  # Create a copy of the Hash where *scope* is appended to the :scopes value.
  #
  # @param [Hash]   item
  # @param [Symbol] scope
  # @param [Hash]   opt               Additional key/value pairs.
  #
  # @return [Hash]                    A modified copy of *item*.
  #
  def add_scope(item, scope, **opt)
    item.merge(opt).merge!(scopes: [*item[:scopes], scope].uniq)
  end

  # count_unique
  #
  # @param [Array<Hash,ActiveSupport::SafeBuffer>] lines
  # @param [String, Symbol]                        type
  # @param [String, nil]                           term
  #
  # @return [String]
  #
  def count_unique(lines, type, term: nil)
    lines = lines.select { |line| line.is_a?(Hash) }
    count = lines.map { |line| line[:"data-#{type}"] }.compact.uniq.size
    "(#{count} %s)" % (term || type).to_s.downcase.pluralize(count)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  SEARCH_FIELD_LEVEL = Search::Record::TitleRecord::HIERARCHY_PATHS

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
    levels = value.is_a?(Array) ? value : SEARCH_FIELD_LEVEL[value&.to_sym]
    levels = levels&.select { |s| s.is_a?(Symbol) || s.is_a?(String) } || []
    levels.map! { |s| "scope-#{s}" }
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
