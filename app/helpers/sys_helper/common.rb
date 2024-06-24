# app/helpers/sys_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Common

  include Emma::Common
  include Emma::Constants

  include LinkHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  SYS_CONFIGURATION = config_section('emma.sys').deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A list of the "/sys" links available to the current user.
  #
  # @param [Symbol, String, Integer, nil] tag   Element wrapping #make_link.
  # @param [Hash]                         opt   Passed to each #make_link.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def action_links(tag: nil, **opt)
    prepend_css!(opt, 'link')
    [:index, *SysController::PAGES].map { |page|
      next if page.to_s == params['action']
      cfg = I18n.t("emma.sys.#{page}", default: {})
      next if (role = cfg[:role]) && !current_user&.has_role?(role)
      html_tag(tag, class: 'page-action') do
        path  = get_path_for(:sys, page)
        label = cfg[:label]
        tip   = cfg[:tooltip]
        l_opt = opt.merge(cfg[:link_opt] || {}).merge!(title: tip).compact
        note  = tip ? html_div(class: 'note') { tip.delete_suffix('.') } : ''
        # noinspection RubyMismatchedArgumentType
        make_link(path, label, **l_opt) << note
      end
    }.compact
  end

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
    html_div('data-turbolinks-permanent': true, **opt) do
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
      label = html_dt(**p_opt) { dt_name(k) }
      value = html_dd(**p_opt) { dd_value(v) }
      label << value
    end
  end

  # Format a name.
  #
  # @param [any, nil] name
  # @param [String]   css             Characteristic CSS class/selector.
  # @param [Hash]     opt
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
  # @param [any, nil] value
  # @param [Integer]  object_wrap
  # @param [String]   css             Characteristic CSS class/selector.
  # @param [Hash]     opt
  #
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dd_value(value, object_wrap: 100, css: 'value', **opt)
    if value.nil? || (value == EMPTY_VALUE)
      value = EMPTY_VALUE
    elsif value.is_a?(ActiveSupport::ExecutionWrapper)
      value = value.class.to_s
      if value.start_with?('#<Class:')
        value << ' (ActiveSupport::ExecutionWrapper)'
      end
    elsif !value.is_a?(ActiveSupport::SafeBuffer)
      value = value.inspect unless value.is_a?(String) && value.end_with?('%')
      if (value.size > object_wrap) && value.start_with?('#<')
        value.gsub!(/ +(@\w+=)/, ("\n" + '  \1')) and value.sub!(/>$/, "\n>")
      end
    end
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
  # @param [Symbol, Hash]      headers  Where the keys become CSS class names.
  # @param [Boolean]           sort
  # @param [String]            css      Characteristic CSS class/selector.
  # @param [Hash]              opt      Passed to the outer `<table>` element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def sys_table(pairs, headers, sort: true, css: '.sys-table', **opt)
    headers = SYS_CONFIGURATION.dig(headers, :headers) if headers.is_a?(Symbol)
    cols    = positive(headers&.size) or raise "#{__method__}: no columns"
    row     = 0
    pairs   = pairs.sort_by(&:first) if sort
    pairs   = pairs.to_h

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
      html_thead do
        html_tr('aria-rowindex': (row += 1)) do
          headers.map.with_index(1) do |(k, v), col|
            tag, role = [:th, 'columnheader']
            html_tag(tag, v, class: k, role: role, 'aria-colindex': col)
          end
        end
      end

    # Generate table body rows.
    body =
      html_tbody do
        column = ->(*values) { headers.transform_values { values.shift } }
        pairs.map do |name, values|
          html_tr('aria-rowindex': (row += 1)) do
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
    html_table('data-turbolinks-permanent': true, **opt) do
      head << body
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Run a system command and return its output.
  #
  # If *command* is an array, it is treated as a sequence of alternate commands
  # which are tried in order until one of them is successful.
  #
  # @param [String, Array<String>] command
  #
  # @return [String]
  #
  def run_command(command)
    err_file = nil
    if command.is_a?(Array)
      command[0...-1].each do |cmd|
        lines = `(#{cmd}) 2>/dev/null`.strip.presence and return lines
      end
      command = command.last
    end
    return "#{__method__}: no command given" if command.blank?
    err_file = Tempfile.new(__method__.to_s)
    result   = `(#{command}) 2>"#{err_file.path}"`.strip.presence
    err_file.rewind
    errors   = err_file.read
    result   = "#{result}\n\n#{errors}" if errors.present?
    result.presence || "COULD NOT RUN #{command.inspect}"
  ensure
    err_file&.close
    # noinspection RubyMismatchedReturnType
    err_file&.unlink
  end

  # Run the system `ls` command.
  #
  # All items at the root are listed and will be recursed into except for the
  # root names present in *ignore*.
  #
  # @param [String, nil]                root
  # @param [String, Array<String>, nil] names
  # @param [String, Array<String>, nil] ignore  Do not recurse into these.
  # @param [String]                     ls_opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ls_command(root: nil, names: %w[.[^.]* *], ignore: nil, ls_opt: 'hlp')
    names  = Array.wrap(names).compact_blank
    names.map! { |name| "#{root}/#{name}" } if root
    names  = names.join(' ')
    ignore = Array.wrap(ignore).compact_blank.presence
    ignore.map! { |name| "#{root}/#{name}" } if root
    ignore = ignore.join("\n")

    dirs   = "ls -dv #{names}"
    dirs   = %Q(#{dirs} | grep -v -x "#{ignore}") if ignore
    dirs   = `#{dirs}`.squish
    cmd    = [
      "ls -dv#{ls_opt} #{names}",             # In place of root-level lines
      'echo',
      "ls -ARv#{ls_opt} #{dirs} | sed '1,/^$/d'" # Skip root-level output lines
    ].join(";\n")

    lines  = run_command(cmd)
    blocks = lines.split("\n\n")

    first  = blocks.shift.split("\n").map! { |line| ls_entry(line, root) }
    first  = first.join("\n").html_safe

    blocks.map! do |block|
      entries = block.split("\n")
      line_1, line_2 = entries.shift(2)
      base = line_1.delete_suffix(':')
      entries.map! { |line| ls_entry(line, base) }
      [line_1, line_2, *entries].join("\n").html_safe
    end
    [first, *blocks].join("\n\n").html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create an `ls` output line, with the name as a link to view it if it is a
  # file.
  #
  # @param [String]      line
  # @param [String, nil] base         Root for file paths.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ls_entry(line, base = nil)
    part = line.split(/\s+/)
    name = (part.last if part.size == 9)
    if name.nil? || name.match?(/[[:punct:]]$/)
      ERB::Util.h(line)
    else
      pos  = line.rindex(name)
      path = '/sys/view?file=%s' % (base ? File.join(base, name) : name)
      ERB::Util.h(line[0...pos]) << external_link(path, name)
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
