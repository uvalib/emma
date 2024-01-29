# app/helpers/md_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display of Math Detective.
#
# @see file:app/assets/stylesheets/controllers/_tool.scss
#
module MdHelper

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Math Detective file input element.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_file_input(css: '.file-prompt', **opt)
    id    = unique_id(css)

    l_txt = config_text(:md, :file, :input, :label)
    label = label_tag(id, "#{l_txt}:", class: 'file-label')

    input = file_field_tag(id, class: 'file-input', accept: 'image/*')

    prepend_css!(opt, css)
    html_div(**opt) do
      label << input
    end
  end

  # Get image for Math Detective from the clipboard.
  #
  # NOTE: Not currently possible with Firefox.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_clipboard_input(css: '.clipboard-prompt', **opt)
    id    = unique_id(css)

    l_txt = config_text(:md, :clipboard, :input, :label)
    l_id  = "label-#{id}"
    l_opt = { class: 'clipboard-label', id: l_id }
    label = html_span("#{l_txt}:", **l_opt)

    c_txt = config_text(:md, :clipboard, :input, :paste)
    c_id  = "button-#{id}"
    c_opt = { class: 'clipboard-input', id: c_id, 'aria-describedby': l_id }
    ctrl  = html_button(c_txt, **c_opt)

    n_opt = { class: 'clipboard-note hidden' }
    note  = html_span('', **n_opt)

    prepend_css!(opt, css)
    html_div(**opt) do
      label << ctrl << note
    end
  end

  # Math Detective file preview element.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_preview(css: '.preview-container.container', **opt)

    l_txt = config_text(:md, :preview, :title)
    l_css = 'preview-label'
    l_id  = unique_id(l_css)
    l_opt = { class: l_css, id: l_id }
    label = html_h2(l_txt, **l_opt)

    i_txt = config_text(:md, :preview, :label)
    i_css = 'file-preview'
    i_opt = { class: i_css, alt: i_txt }
    image = html_tag(:img, **i_opt)

    prepend_css!(opt, css)
    html_div(**opt) do
      label << image
    end
  end

  # Math Detective execution status.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_status(css: '.status-container.container', **opt)

    l_txt = config_text(:md, :status, :label)
    l_css = 'status-label'
    l_id  = unique_id(l_css)
    label = html_span("#{l_txt}:", class: l_css, id: l_id)

    v_txt = config_text(:md, :status, :placeholder)
    value = html_span(v_txt, class: 'status')

    prepend_css!(opt, css)
    opt[:'aria-describedby'] ||= l_id
    html_div(**opt) do
      label << value
    end
  end

  # Math Detective error report.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_error(css: '.error-container.container', **opt)

    none_txt = config_text(:md, :error, :label)
    none_css = 'no-equations'
    none_opt = { class: "#{none_css} hidden" }
    none     = html_div(none_txt, **none_opt)

    note_txt = config_text(:md, :error, :placeholder)
    note_css = 'error-message'
    note_opt = { class: "#{note_css} hidden" }
    note     = html_div(note_txt, **note_opt)

    prepend_css!(opt, css)
    html_div(**opt) do
      none << note
    end
  end

  # Math Detective MathML output.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_mathml(**opt)
    # css   = '.mathml-container'
    heading = config_text(:md, :mathml, :title)
    md_output_container('mathml', heading, **opt)
  end

  # Math Detective LaTeX output.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_latex(**opt)
    # css   = '.latex-container'
    heading = config_text(:md, :latex, :title)
    md_output_container('latex', heading, **opt)
  end

  # Math Detective spoken language text output.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_spoken(**opt)
    # css   = '.spoken-container'
    heading = config_text(:md, :spoken, :title)
    md_output_container('spoken', heading, **opt)
  end

  # Math Detective API JSON results.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_results(**opt)
    # css   = '.api-container'
    heading = config_text(:md, :results, :title)
    md_output_container('api', heading, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A container for a Math Detective output type.
  #
  # @param [String,Symbol] name
  # @param [String,Symbol] label
  # @param [Hash]          opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_output_container(name, label, **opt)
    css   = ".#{name}-container.container"

    l_tag = :h2
    l_css = "#{name}-label"
    l_id  = unique_id(l_css)
    l_opt = { class: "#{l_css} label-text", id: l_id }
    label = html_tag(l_tag, label, **l_opt)

    v_tag = :textarea
    v_txt = config_text(:md, :output, :placeholder)
    v_css = 'output'
    v_opt = { class: v_css, 'aria-labelledby': l_id }
    v_opt[:spellcheck] = false if v_tag == :textarea
    value = html_tag(v_tag, v_txt, **v_opt)

    prepend_css!(opt, css)
    opt[:'aria-describedby'] ||= l_id
    html_div(**opt) do
      label = html_div(class: 'label-line') { label << clipboard_icon }
      label << value
    end
  end

  CLIPBOARD_ICON = '&#128203;'.html_safe.freeze

  # Clipboard icon to act as a button for copying the text of the associated
  # output element.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def clipboard_icon(css: '.clipboard-icon', **opt)
    opt[:role]         ||= 'button'
    opt[:title]        ||= config_text(:md, :copy, :tooltip)
    opt[:'aria-label'] ||= opt[:title]
    prepend_css!(opt, css)
    html_span(**opt) do
      symbol_icon(CLIPBOARD_ICON)
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
