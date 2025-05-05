# app/helpers/html_helper/tags.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper HTML support methods.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module HtmlHelper::Tags

  include HtmlHelper::Attributes
  include HtmlHelper::Options

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Short-cut for generating an HTML '<span>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_span(*args, **opt, &blk)
    html_tag(:span, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<strong>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_bold(*args, **opt, &blk)
    html_tag(:strong, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<em>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_italic(*args, **opt, &blk)
    html_tag(:em, *args, **opt, &blk)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Short-cut for generating an HTML '<div>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_div(*args, **opt, &blk)
    html_tag(:div, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<p>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_paragraph(*args, **opt, &blk)
    html_tag(:p, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<h1>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_h1(*args, **opt, &blk)
    html_tag(:h1, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<h2>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_h2(*args, **opt, &blk)
    html_tag(:h2, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<h3>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_h3(*args, **opt, &blk)
    html_tag(:h3, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<dl>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_dl(*args, **opt, &blk)
    html_tag(:dl, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<dt>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_dt(*args, **opt, &blk)
    html_tag(:dt, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<dd>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_dd(*args, **opt, &blk)
    html_tag(:dd, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<ol>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_ol(*args, **opt, &blk)
    html_tag(:ol, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<ul>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_ul(*args, **opt, &blk)
    html_tag(:ul, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<li>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_li(*args, **opt, &blk)
    html_tag(:li, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<table>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_table(*args, **opt, &blk)
    html_tag(:table, *args, role: 'table', **opt, &blk)
  end

  # Short-cut for generating an HTML '<thead>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_thead(*args, **opt, &blk)
    html_tag(:thead, *args, role: 'rowgroup', **opt, &blk)
  end

  # Short-cut for generating an HTML '<tbody>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_tbody(*args, **opt, &blk)
    html_tag(:tbody, *args, role: 'rowgroup', **opt, &blk)
  end

  # Short-cut for generating an HTML '<tr>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_tr(*args, **opt, &blk)
    html_tag(:tr, *args, role: 'row', **opt, &blk)
  end

  # Short-cut for generating an HTML '<th>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_th(*args, **opt, &blk)
    html_tag(:th, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<td>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_td(*args, **opt, &blk)
    html_tag(:td, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<legend>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_legend(*args, **opt, &blk)
    html_tag(:legend, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<fieldset>' element with a legend.
  #
  # @param [String, nil] legend
  # @param [Array<*>]    content
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional content
  # @yieldreturn [String, Array]
  #
  def html_fieldset(legend, *content, **opt)
    legend &&= html_legend(legend)    unless legend.html_safe?
    content.prepend(legend)           if legend.present?
    content.concat(Array.wrap(yield)) if block_given?
    html_tag(:fieldset, *content, **opt)
  end

  # Short-cut for generating an HTML '<button>' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_button(*args, **opt, &blk)
    label   = args.first.presence
    symbols = only_symbols?(label)
    accessible_name?(*args, **opt) if Log.debug? && (symbols || label.blank?)
    args[0] = symbol_icon(label) if symbols
    html_tag(:button, *args, **opt, &blk)
  end

  # Short-cut for generating an HTML '<details>' element.
  #
  # For easier styling, additional content is wrapped in a '.content' element.
  #
  # @param [String]   summary         The text visible when not expanded.
  # @param [Array<*>] content         Appended to the '.content' element.
  # @param [String]   id              Passed to the inner `<summary>` element.
  # @param [String]   title           Passed to the inner `<summary>` element.
  # @param [Hash]     opt             Passed to the outer `<details>` element.
  # @param [Proc]     blk             Appended to the '.content' element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_details(summary, *content, id: nil, title: nil, **opt, &blk)
    title ||= config_term(:details, :tooltip)
    summary = html_tag(:summary, summary, id: id, title: title)
    content = html_div(*content, class: 'content', &blk)
    html_tag(:details, **opt) do
      summary << content
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Short-cut for generating an HTML element which normalizes element contents
  # provided via the parameter list and/or the block.
  #
  # If *tag* is a number it is translated to 'h1'-'h6'.  If *tag* is 0 or *nil*
  # then it defaults to 'div'.
  #
  # @param [Symbol, String, Integer, nil] tag
  # @param [any, nil]                     args
  # @param [String, nil]                  separator   Between *args*.
  # @param [Hash]                         opt         Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Additional content
  # @yieldreturn [String, Array]
  #
  # @see ActionView::Helpers::TagHelper#content_tag
  #
  def html_tag(tag, *args, separator: "\n", **opt)
    lvl = positive(tag)
    tag = nil if tag.is_a?(Numeric)
    tag = lvl && ('h%d' % [lvl, 6].min) || tag || 'div'

    opt = args.pop.dup if opt.blank? && args.last.is_a?(Hash)
    add_inferred_attributes!(tag, opt)
    add_required_attributes!(tag, opt)
    html_options!(opt)
    check_required_attributes(tag, opt, meth: calling_method) if Log.debug?

    args.concat(Array.wrap(yield)) if block_given?
    args = args.flatten.compact_blank
    args = safe_join(args, separator)

    content_tag(tag, args, opt)
  end

  # Invoke #form_tag after normalizing element contents provided via the
  # parameter list and/or the block.
  #
  # @param [String, Hash] url_or_path
  # @param [any, nil]     args
  # @param [String, nil]  separator   Between *args*.
  # @param [Hash]         opt         Passed to #form_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @yield Form contents
  # @yieldreturn [String, Array]
  #
  def html_form(url_or_path, *args, separator: "\n", **opt)
    opt  = args.pop.dup if opt.blank? && args.last.is_a?(Hash)
    args.concat(Array.wrap(yield)) if block_given?
    args = args.flatten.compact_blank
    form_tag(url_or_path, opt) do
      safe_join(args, separator)
    end
  end

  # Make a Unicode character (sequence) into a decorative element that is not
  # pronounced by screen readers.
  #
  # @param [any, nil] icon            Char(s) that should match #SYMBOLS.
  # @param [String]   css             Characteristic CSS class/selector.
  # @param [Hash]     opt             Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def symbol_icon(icon, css: '.symbol', **opt)
    icon = icon.to_s unless icon.is_a?(String)
    opt[:'aria-hidden'] = true unless opt.key?(:'aria-hidden')
    prepend_css!(opt, css)
    html_span(icon, **opt)
  end

end

__loading_end(__FILE__)
