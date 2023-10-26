# app/helpers/sys_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Common

  include Emma::Constants

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Translate Hash keys and values into an element containing pairs of
  # dt and dd elements.
  #
  # @param [Array, Hash] hdrs
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dt_dd_section(hdrs, css: '.pairs', **opt)
    prepend_css!(opt, css)
    html_div('data-turbolinks-cache': false, **opt) do
      dt_dd_lines(hdrs)
    end
  end

  # Translate Hash keys and values into pairs of dt and dd elements.
  #
  # @param [Array, Hash] hdrs
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dt_dd_lines(hdrs)
    unless hdrs.is_a?(Hash)
      hdrs = hdrs.is_a?(Array) ? hdrs.flatten : Array.wrap(hdrs)
      hdrs = hdrs.map! { |name| [name, request.get_header(name)] }.to_h
    end
    # noinspection RubyMismatchedArgumentType
    safe_join(dt_dd_pairs(hdrs), "\n")
  end

  # Translate Hash keys and values into pairs of dt and dd elements.
  #
  # @param [Hash] pairs
  # @param [Hash] opt                 Passed to `<dt>` and `<dd>`.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def dt_dd_pairs(pairs, **opt)
    pairs.map do |k, v|
      blank = v.nil? || (v == EMPTY_VALUE)
      p_opt = append_css(opt, (blank ? 'blank' : 'present'))
      label = html_tag(:dt, **p_opt) { dt_name(k) }
      value = html_tag(:dd, **p_opt) { dd_value(v) }
      label << value
    end
  end

  # Format a name.
  #
  # @param [*]      name
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dt_name(name, css: 'name', **opt)
    name = name&.to_s || EMPTY_VALUE
    prepend_css!(opt, css)
    html_div(name, **opt)
  end

  # Format a value.
  #
  # @param [*]       value
  # @param [Integer] object_wrap
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt
  #
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dd_value(value, object_wrap: 100, css: 'value', **opt)
    unless value.nil? || (value == EMPTY_VALUE)
      if value.is_a?(ActiveSupport::ExecutionWrapper)
        value = value.class.to_s
        if value.start_with?('#<Class:')
          value << ' (ActiveSupport::ExecutionWrapper)'
        end
      else
        value = value.inspect
        if (value.size > object_wrap) && value.start_with?('#<')
          value.gsub!(/ +(@\w+=)/, ("\n" + '  \1')) and value.sub!(/>$/, "\n>")
        end
      end
    end
    value = value&.to_s || EMPTY_VALUE
    prepend_css!(opt, css)
    html_div(value, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render a table for "/sys" pages.
  #
  # @param [Hash,Array<Array>] pairs
  # @param [Hash]              headers  Where the keys become CSS class names.
  # @param [Boolean]           sort
  # @param [String]            css      Characteristic CSS class/selector.
  # @param [Hash]              opt      Passed to the outer `<table>` element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def sys_table(pairs, headers, sort: true, css: '.sys-table', **opt)
    cols  = positive(headers&.size) or raise "#{__method__}: no columns"
    row   = 0
    pairs = pairs.sort_by(&:first) if sort
    pairs = pairs.to_h

    if sanity_check?
      pairs.each_pair do |k, v|
        case [k, *v].size <=> cols
          when -1 then raise "#{__method__}: too few columns: #{v.inspect}"
          when +1 then raise "#{__method__}: too many columns: #{v.inspect}"
        end
      end
    end

    # Generate table header row.
    head =
      html_tag(:thead) do
        html_tag(:tr, 'aria-rowindex': (row += 1)) do
          headers.map.with_index(1) do |(k, v), col|
            tag, role = [:th, 'columnheader']
            html_tag(tag, v, class: k, role: role, 'aria-colindex': col)
          end
        end
      end

    # Generate table body rows.
    body =
      html_tag(:tbody) do
        column = ->(*values) { headers.transform_values { values.shift } }
        pairs.map do |name, values|
          html_tag(:tr, 'aria-rowindex': (row += 1)) do
            column.(name, *values).map.with_index(1) do |(k, v), col|
              tag, role = (col == 1) ? [:th, 'rowheader'] : [:td, 'cell']
              html_tag(tag, v, class: k, role: role, 'aria-colindex': col)
            end
          end
        end
      end

    # Generate the table.
    opt[:'aria-rowcount'] = 1 + pairs.size
    opt[:'aria-colcount'] = cols
    prepend_css!(opt, css, "columns-#{cols}")
    html_tag(:table, 'data-turbolinks-cache': false, **opt) do
      head << body
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
