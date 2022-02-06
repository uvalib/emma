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

  include LayoutHelper::SearchBar

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
  def md_input(**opt)
    css_selector = '.input-prompt'

    input_css    = 'file-input'
    input_id     = unique_id(input_css)
    input        = file_field_tag(input_id, class: input_css)

    label_css    = 'input-label'
    label        = 'Select a file' # TODO: I18n
    label        = label_tag(input_id, "#{label}:", class: label_css)

    prepend_classes!(opt, css_selector)
    html_div(opt) do
      label << input
    end
  end

  # Math Detective file preview element.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_preview(**opt)
    css_selector = '.preview-container.container'

    label_css    = 'preview-label'
    label_id     = unique_id(label_css)
    label        = 'Image Preview' # TODO: I18n
    label        = html_tag(:h2, label, class: label_css, id: label_id)

    image_css    = 'file-preview'
    image_alt    = 'Preview of selected file' # TODO: I18n
    image_opt    = { class: image_css, alt: image_alt }
    image        = html_tag(:img, image_opt)

    prepend_classes!(opt, css_selector)
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
    css_selector = '.status-container.container'

    label_css    = 'status-label'
    label_id     = unique_id(label_css)
    label        = 'Status' # TODO: I18n
    label        = label_tag(nil, "#{label}:", class: label_css, id: label_id)

    value_text   = 'NONE' # Placeholder
    value        = html_span(value_text, class: 'status')

    prepend_classes!(opt, css_selector)
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
    css_selector = '.error-container.container'

    none_css     = 'no-equations'
    none_text    = 'No equations detected.' # TODO: I18n
    none         = html_div(none_text, class: "#{none_css} hidden")

    message_css  = 'error-message'
    message_text = 'NONE' # Placeholder
    message      = html_div(message_text, class: "#{message_css} hidden")

    prepend_classes!(opt, css_selector)
    html_div(opt) do
      none << message
    end
  end

  # Math Detective MathML output.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def md_mathml(**opt)
    # css_selector = '.mathml-container'
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
    # css_selector = '.latex-container'
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
    # css_selector = '.spoken-container'
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
    # css_selector = '.api-container'
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
    css_selector = ".#{name}-container.container"

    label_css    = "#{name}-label"
    label_id     = unique_id(label_css)
    label        = html_tag(:h2, label, class: label_css, id: label_id)

    output_text  = 'NONE' # Placeholder
    output       = html_div(output_text, class: 'output')

    prepend_classes!(opt, css_selector)
    opt[:'aria-labelledby'] ||= label_id
    html_div(opt) do
      label << clipboard_icon << output
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
    prepend_classes!(opt, 'clipboard-icon')
    opt[:title] ||= 'Copy to clipboard' # TODO: I18n
    opt[:role]  ||= 'button'
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
