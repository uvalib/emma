# app/decorators/base_decorator/hierarchy.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting the hierarchical display of model records.
#
# @note In use with Search items but untested with any other Model class.
#
module BaseDecorator::Hierarchy

  include BaseDecorator::Common
  include BaseDecorator::Fields
  include BaseDecorator::List

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render field/value pairs of a title-level record.
  #
  # @param [String, Symbol, nil] action
  # @param [Hash, nil]           pairs
  # @param [String, nil]         separator  Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  #
  # @option opt [Integer] :index            Offset to make unique element IDs
  #                                           passed to #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #item_lines
  # @see Search::Record::TitleRecord#field_hierarchy
  #
  def render_field_hierarchy(action: nil, pairs: nil, separator: nil, **opt)
    return ''.html_safe if blank?
    separator  ||= DEFAULT_ELEMENT_SEPARATOR

    opt[:row]    = 0
    opt[:action] = action
    opt.delete(:'aria-rowindex')

    # Get the hierarchy of field/value pairs, inserting additional field/value
    # pairs (if any) at the title level.
    hierarchy = object.field_hierarchy
    if pairs.present?
      hierarchy = hierarchy.dup
      pairs =
        pairs.reject do |k, v|
          hierarchy[k] = v if v.is_a?(Hash) || v.is_a?(Array)
        end
      hierarchy.reverse_merge!(nil => { nil => pairs }) if pairs.present?
    end

    # Create a decorator for each file-level record.
    records = object.records
    opt[:record_map] = records.map { |r| [r.emma_recordId, decorate(r)] }.to_h

    # Get a line for each metadata field/pair and plus interstitial content.
    lines = item_lines(hierarchy, opt)
    trace_attrs!(opt)
    lines.map! { |v| v.is_a?(Hash) ? render_field(v, opt) : ERB::Util.h(v) }
    lines.unshift(nil).join(separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The term used for a file instance instead of 'file'.
  #
  # @type [String, nil]
  #
  FILE_TERM     = config_term(:hierarchy, :file_term).freeze
  COMPLETE_WORK = config_term(:hierarchy, :complete).freeze

  # Data for all of the lines that represent a hierarchical entry.
  #
  # @param [Hash] hierarchy           From `object.field_hierarchy`.
  # @param [Hash] opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  # @see "en.emma.page.search.field_hierarchy"
  #
  def item_lines(hierarchy, opt)
    item_index = [opt[:index]]
    item_prop  = { record: self }
    skip_opt   = { meth: __method__, except: { hash: :title, array: :parts } }
    level      = opt.delete(:level)
    hierarchy.flat_map { |main_key, main_section|
      next if skip_entry?(main_key, main_section, **skip_opt)
      main_index = item_index
      main_prop  = add_scope(item_prop, main_key)
      if main_key == :title
        title_level_lines(main_section, main_index, main_prop, opt)
      else
        main_prop.merge!(level: level) if level
        part_level_lines(main_section, main_index, main_prop, opt)
      end
    }.compact_blank!
  end

  # Data for the lines of title-level information which relates to the overall
  # creative work.
  #
  # @param [Hash]  main_section
  # @param [Array] main_index
  # @param [Hash]  main_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  # @see "en.emma.page.search.field_hierarchy.title"
  #
  def title_level_lines(main_section, main_index, main_prop, opt)
    file_section_lines(main_section, main_index, main_prop, opt)
  end

  # Data for the lines representing all portions of a work (e.g. volumes) as
  # indicated by bibliographic metadata across all of the related file-level
  # records.
  #
  # Each portion is represented in the return value by an HTML heading entry
  # (indicating the volume number) followed by multiple Hash/HTML entries for
  # each format available for that portion.
  #
  # @param [Array<Hash>] main_section
  # @param [Array]       main_index
  # @param [Hash]        main_prop
  # @param [Hash]        opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  # @see "en.emma.page.search.field_hierarchy.parts"
  #
  def part_level_lines(main_section, main_index, main_prop, opt)
    many_parts = main_section.many?
    this_level = main_prop[:level]
    next_level = this_level&.next
    main_section.flat_map.with_index(1) do |part, part_no|
      index = [*main_index, part_no]
      prop  = main_prop.merge('data-part': part_no, level: next_level)

      # Defer the heading row until the enclosed information is gathered.
      h_row = opt[:row]
      opt[:row] += 1
      lines = part_section_lines(part, index, prop, opt)

      # Create the heading row.
      value   = part.dig(:bibliographic, :bib_seriesPosition).presence
      if many_parts && !value
        value = :all
        name  = ERB::Util.h(COMPLETE_WORK)
      else
        name  = value&.inspect || part_no
      end
      details = count_unique(lines, :format)
      h_prop  = prop.merge(level: this_level)
      h_opt   = opt.merge(row: h_row)
      heading = new_section(:part, name, value, details, index, h_prop, h_opt)

      [heading, *lines]
    end
  end

  # Data for the lines representing a specific portion of a work (e.g. volume).
  #
  # @param [Hash]  part
  # @param [Array] part_index
  # @param [Hash]  part_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  # @see "en.emma.page.search.field_hierarchy.parts.*"
  #
  def part_section_lines(part, part_index, part_prop, opt)
    skip_opt = { meth: __method__, except: { array: :formats } }
    part.flat_map { |part_key, part_section|
      next if part_key == :bibliographic
      next if skip_entry?(part_key, part_section, **skip_opt)
      part_lines(part_section, part_key, part_index, part_prop, opt)
    }.compact_blank!
  end

  # Data for the lines representing all of the available formats for a specific
  # portion of a work (e.g. volume).
  #
  # Each format is represented in the return value by an HTML heading entry
  # (indicating the format) followed by multiple Hash/HTML entries for that
  # format.
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
  # @see "en.emma.page.search.field_hierarchy.parts.files"
  #
  def part_lines(part_section, part_key, part_index, part_prop, opt)
    opt[:term] = FILE_TERM unless (original_term = opt[:term])
    this_level = part_prop[:level]
    next_level = this_level&.next
    part_section.flat_map.with_index(1) { |format, format_no|
      index = [*part_index, format_no]
      prop  = add_scope(part_prop, part_key, index: index)
      prop[:'data-format'] = format_no
      prop[:level]         = next_level

      # Defer the heading row until the enclosed information is gathered.
      h_row = opt[:row]
      opt[:row] += 1
      lines = format_section_lines(format, index, prop, opt)

      # Create the heading row.
      value   = format.dig(:bibliographic, :dc_format).presence
      name    = value ? ERB::Util.h(value.titleize.upcase) : format_no
      details = count_unique(lines, :file, term: opt[:term])
      prop    = prop.merge(level: this_level)
      h_opt   = opt.merge(row: h_row)
      heading = new_section(:format, name, value, details, index, prop, h_opt)

      [heading, *lines]
    }.tap {
      opt[:term] = original_term
    }
  end

  # Data for the lines representing all of the copies of a specific format of a
  # portion of a work.
  #
  # @param [Hash]  format
  # @param [Array] format_index
  # @param [Hash]  format_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash,ActiveSupport::SafeBuffer>]
  #
  # @see "en.emma.page.search.field_hierarchy.parts.files"
  #
  def format_section_lines(format, format_index, format_prop, opt)
    skip_opt = { meth: __method__, except: { array: :files } }
    format.flat_map { |fmt_key, fmt_entry|
      next if fmt_key == :bibliographic
      next if skip_entry?(fmt_key, fmt_entry, **skip_opt)
      file_lines(fmt_entry, fmt_key, format_index, format_prop, opt)
    }.compact_blank!
  end

  # Data for the lines representing each copy of a specific format of a portion
  # of a work.
  #
  # Each copy is represented in the return value by an HTML heading entry
  # followed by multiple Hash entries for that copy.
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
      lines   = file_section_lines(file, index, prop.except(:level), opt)
      [heading, *lines]
    end
  end

  # Data for the lines representing all of the sets of metadata items of a
  # unique copy of a specific format of a portion of a work.
  #
  # @param [Hash]  section
  # @param [Array] section_index
  # @param [Hash]  section_prop
  # @param [Hash]  opt
  #
  # @return [Array<Hash>]
  #
  # @see "en.emma.page.search.field_hierarchy.title.*"
  # @see "en.emma.page.search.field_hierarchy.parts.*"
  # @see "en.emma.page.search.field_hierarchy.parts.formats.*"
  # @see "en.emma.page.search.field_hierarchy.parts.formats.files.*"
  #
  def file_section_lines(section, section_index, section_prop, opt)
    skip_opt = { meth: __method__, except: { hash: '*' } }
    section.flat_map { |section_key, section_entry|
      next if skip_entry?(section_key, section_entry, **skip_opt)
      prop = add_scope(section_prop, section_key, index: section_index)
      field_lines(section_entry, prop, opt)
    }.compact_blank!
  end

  # Data for the lines representing a set of metadata items of a unique copy
  # of a specific format of a portion of a work.
  #
  # @param [Hash] pairs
  # @param [Hash] field_prop
  # @param [Hash] opt
  #
  # @return [Array<Hash>]
  #
  # @see "en.emma.page.search.field_hierarchy.**.bibliographic"
  # @see "en.emma.page.search.field_hierarchy.**.repository"
  # @see "en.emma.page.search.field_hierarchy.**.index"
  # @see "en.emma.page.search.field_hierarchy.**.remediation"
  # @see "en.emma.page.search.field_hierarchy.**.accessibility"
  #
  def field_lines(pairs, field_prop, opt)
    property_pairs(pairs: pairs, **opt).map { |_field, prop|
      prop.merge(field_prop, row: (opt[:row] += 1))
    }.compact_blank!
  end

  # Render a single field label and value.
  #
  # @param [Hash] line
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_field(line, opt)
    label, record, field = line.values_at(:label, :record, :field)
    v_opt  = opt.slice(:index, :min_index, :max_index, :no_fmt)
    value  = record.list_field_value(line[:value], field: field, **v_opt)
    scopes = field_scopes(line[:scopes])
    opt[:row]              = line[:row]
    opt[:index]            = Array.wrap(line[:index]).compact.join('-')
    opt[:'data-raw-value'] = Array.wrap(line[:value]).compact.join('|')
    opt = append_css(opt, scopes) if scopes.present?
    opt.delete(:level) # Label/value pairs are "leaf nodes".
    trace_attrs!(opt)
    render_line(label, value, prop: line, **opt)
  end

  # A heading/divider between sections within a compound search item, which is
  # rendered as a toggle for a collapsible container.
  #
  # @note SIDE EFFECT: `opt[:row]` will be incremented.
  #
  # @param [Symbol, String] type
  # @param [any, nil]       name        Distinct section indicator.
  # @param [any, nil]       data_value  For 'data-value'.
  # @param [any, nil]       details
  # @param [any, nil]       index       Unique line indicator.
  # @param [Hash]           prop
  # @param [Hash]           opt         Passed to #render_line.
  #
  # @option opt [String] :term          Override #FILE_TERM.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def new_section(type, name, data_value, details, index, prop, opt)
    css = '.field-section'
    opt[:row] += 1
    open  = true
    type  = type.to_s
    field = :"new_#{type.underscore}"
    base  = model_html_id(field)
    index = index.compact.join('-') if index.is_a?(Array)
    level = prop[:level]

    # The open/close toggle control for this section.
    tgt_id = [(PAIR_WRAPPER || 'value'), base, index].compact.join('-')
    toggle = list_item_toggle(id: tgt_id, context: type, open: open)

    # Prepend the toggle control to the label.
    label = name
    unless label.is_a?(ActiveSupport::SafeBuffer)
      term  = (opt[:term] || type).to_s.titleize
      label = "#{term} #{label}".strip
    end
    label = toggle << html_span(label, class: 'text')

    # Make an non-empty value portion.
    value = details || HTML_SPACE
    value = html_span(value, class: 'details')

    opt = prepend_css(opt, css)
    append_css!(opt, 'open') if open
    opt.merge!(role: 'heading', 'aria-level': level) if level
    opt.merge!(index: index, field: field, 'data-value': data_value)
    opt.merge!(prop.select { |k, _| k.start_with?('data-') })
    trace_attrs!(opt)
    render_line(label, value, **opt)
  end

  # list_item_toggle
  #
  # @param [Integer] row
  # @param [Hash]    opt              Passed to TreeHelper#tree_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:javascripts/controllers/search.js *setupToggleControl()*
  #
  def list_item_toggle(row: nil, **opt)
    if (row = positive(row))
      row = "row-#{row}"
      prepend_css!(opt, row)
      opt[:'data-row'] ||= ".#{row}"
    end
    opt[:context] ||= :item
    trace_attrs!(opt)
    tree_button(**opt)
  end

  # Render a single label/value line.
  #
  # @param [String, Symbol, nil] label
  # @param [any, nil]            value
  # @param [Hash]                opt        Passed #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_line(label, value, **opt)
    if value.present?
      opt.except!(:action, :record_map, :term)
      trace_attrs!(opt)
      render_pair(label, value, **opt)
    end || ''.html_safe
  end

  # Indicate whether a section should be ignored, either because its name
  # starts with an underscore (indicating "out-of-band" information) or because
  # it was indicated by the :except parameter.
  #
  # @param [Symbol]              key
  # @param [any, nil]            value
  # @param [Symbol]              meth
  # @param [Hash, Array, Symbol] except
  #
  def skip_entry?(key, value, meth: nil, except: nil, **)
    return true if key.blank? || key.start_with?('_')
    ok = { hash: [], array: [] }
    if except.is_a?(Hash)
      ok.merge!(except)
    elsif except
      ok.transform_values! { except }
    end
    ok.transform_values! { |v| Array.wrap(v).compact }
    ok.transform_values! { |v| v.include?('*') ? [key] : v.map!(&:to_sym) }
    if value.is_a?(Hash)
      return false if ok[:hash].include?(key)
    elsif value.is_a?(Array)
      return false if ok[:array].include?(key)
    else
      Log.debug do
        err = value.presence ? "unexpected value (#{value.inspect})" : 'empty'
        "#{meth || __method__}: #{key}: #{err}"
      end
    end
    true
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

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
