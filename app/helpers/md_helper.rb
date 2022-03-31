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
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_file_input(**opt)
    css       = '.file-prompt'

    input_css = 'file-input'
    input_id  = unique_id(input_css)
    input_opt = { class: input_css, accept: 'image/*' }
    input     = file_field_tag(input_id, input_opt)

    label_txt = 'Image file' # TODO: I18n
    label_css = 'file-label'
    label_opt = { class: label_css }
    label     = label_tag(input_id, "#{label_txt}:", label_opt)

    prepend_css!(opt, css)
    html_div(opt) do
      label << input
    end
  end

  # Get image for Math Detective from the clipboard.
  #
  # NOTE: Not currently possible with Firefox.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_clipboard_input(**opt)
    css       = '.clipboard-prompt'

    input_txt = 'Paste' # TODO: I18n
    input_css = 'clipboard-input'
    input_id  = unique_id(input_css)
    input_opt = { class: input_css, id: input_id }
    input     = html_tag(:button, input_txt, input_opt)

    label_txt = 'Clipboard image' # TODO: I18n
    label_css = 'clipboard-label'
    label_opt = { class: label_css }
    label     = label_tag(input_id, "#{label_txt}:", label_opt)

    note_css  = 'clipboard-note'
    note_opt  = { class: "#{note_css} hidden" }
    note      = html_span('', note_opt)

    prepend_css!(opt, css)
    html_div(opt) do
      label << input << note
    end
  end

  # Math Detective file preview element.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_preview(**opt)
    css       = '.preview-container.container'

    label_tag = :h2
    label_css = 'preview-label'
    label_id  = unique_id(label_css)
    label_txt = 'Selected Image' # TODO: I18n
    label_opt = { class: label_css, id: label_id }
    label     = html_tag(label_tag, label_txt, label_opt)

    image_css = 'file-preview'
    image_alt = 'Preview of selected file' # TODO: I18n
    image_opt = { class: image_css, alt: image_alt }
    image     = html_tag(:img, image_opt)

    prepend_css!(opt, css)
    html_div(opt) do
      label << image
    end
  end

  # Math Detective execution status.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_status(**opt)
    css       = '.status-container.container'

    label_tag = :label
    label_css = 'status-label'
    label_id  = unique_id(label_css)
    label_txt = 'Status' # TODO: I18n
    label_opt = { class: label_css, id: label_id }
    label     = html_tag(label_tag, "#{label_txt}:", label_opt)

    value_txt = 'NONE' # Placeholder
    value_opt = { class: 'status' }
    value     = html_span(value_txt, value_opt)

    prepend_css!(opt, css)
    opt[:'aria-labelledby'] ||= label_id
    html_div(opt) do
      label << value
    end
  end

  # Math Detective error report.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_error(**opt)
    css      = '.error-container.container'

    none_txt = 'No equations detected.' # TODO: I18n
    none_css = 'no-equations'
    none_opt = { class: "#{none_css} hidden" }
    none     = html_div(none_txt, none_opt)

    note_txt = 'NONE' # Placeholder
    note_css = 'error-message'
    note_opt = { class: "#{note_css} hidden" }
    note     = html_div(note_txt, note_opt)

    prepend_css!(opt, css)
    html_div(opt) do
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
    heading = 'Equation(s) as MathML' # TODO: I18n
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
    heading = 'Equation(s) as LaTeX' # TODO: I18n
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
    heading = 'Equation(s) as spoken English' # TODO: I18n
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
    heading = 'Math Detective API Response Data' # TODO: I18n
    md_output_container('api', heading, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A container for a Math Detective output type.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_output_container(name, label, **opt)
    css        = ".#{name}-container.container"

    label_tag  = :h2
    label_css  = "#{name}-label"
    label_id   = unique_id(label_css)
    label_opt  = { class: "#{label_css} label-text", id: label_id }
    label      = html_tag(label_tag, label, label_opt)

    output_tag = :textarea
    output_txt = 'NONE' # Placeholder
    output_css = 'output'
    output_opt = { class: output_css }
    output_opt[:spellcheck] = false if output_tag == :textarea
    output     = html_tag(output_tag, output_txt, output_opt)

    prepend_css!(opt, css)
    opt[:'aria-labelledby'] ||= label_id
    html_div(opt) do
      label = html_div(class: 'label-line') { label << clipboard_icon }
      label << output
    end
  end

  CLIPBOARD_ICON = '&#128203;'.html_safe.freeze

  # Clipboard icon to act as a button for copying the text of the associated
  # output element.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def clipboard_icon(**opt)
    css           = '.clipboard-icon'
    opt[:title] ||= 'Copy this output to clipboard' # TODO: I18n
    opt[:role]  ||= 'button'
    prepend_css!(opt, css)
    html_span(CLIPBOARD_ICON, opt)
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
