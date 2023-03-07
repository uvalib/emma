# app/decorators/base_decorator/lookup.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting bibliographic lookup and related elements.
#
module BaseDecorator::Lookup

  include BaseDecorator::Common
  include BaseDecorator::Configuration

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  ACTION_ATTR = BaseDecorator::Controls::ACTION_ATTR

  # The CSS class selector associated with bibliographic lookup buttons.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/modal-dialog.js ModalDialog.SELECTOR_ATTR
  #
  LOOKUP_CLASS = '.lookup-popup'

  # The JavaScript ModalDialog subclass for bibliographic lookup popups.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/modal-dialog.js ModalDialog.CLASS_ATTR
  # @see file:javascripts/shared/lookup-modal.js LookupModal
  #
  LOOKUP_JS_CLASS = 'LookupModal'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Bibliographic lookup control which engages #lookup_modal.
  #
  # In addition to creating the control, this method also adds the modal to
  # the page modals (unless it already has been added).
  #
  # @param [String] js              ModalDialog subclass.
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to #lookup_modal except for:
  #
  # @option opt [Hash]          :button         To #lookup_button_options.
  # @option opt [Symbol]        :type           Passed to #make_popup_toggle.
  # @option opt [Symbol,String] :'data-action'  Passed to #make_popup_toggle.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LayoutHelper::PageModals#add_page_modal
  #
  def lookup_control(js: LOOKUP_JS_CLASS, css: LOOKUP_CLASS, **opt)
    type  = opt.delete(:type)
    m_opt = { 'data-modal-class': js, 'data-modal-selector': css }
    b_opt = extract_hash!(opt, ACTION_ATTR).merge!(opt.delete(:button) || {})
    b_opt = lookup_button_options(**b_opt, **m_opt)
    h.add_page_modal(css) { lookup_modal(**opt, **m_opt) }
    h.make_popup_toggle(button: b_opt, type: type)
  end

  # A modal popup for bibliographic lookup.
  #
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to #modal_popup except for:
  #
  # @option opt [Hash] :container   Options for #lookup_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def lookup_modal(css: LOOKUP_CLASS, **opt)
    c_opt = opt.delete(:container) || {}
    opt[:close]        = lookup_cancel_options
    opt[:controls]     = lookup_commit_button
    opt[:'aria-label'] = 'Search for additional bibliographic details' # TODO: I18n
    prepend_css!(opt, css)
    h.modal_popup(**opt) do
      lookup_container(**c_opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The options to create a toggle button to activate the bibliographic
  # lookup popup.
  #
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @option opt [Hash] :label       Override the default button label.
  #
  # @return [Hash]
  #
  # @see PopupHelper#inline_popup
  #
  def lookup_button_options(css: '.lookup-button', **opt)
    opt[:label] ||= 'Lookup' # TODO: I18n
    prepend_css!(opt, css)
  end

  # lookup_cancel_options
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def lookup_cancel_options(**opt)
    opt[:label] ||= 'Cancel' # TODO: I18n
    opt[:title] ||= "Don't make any changes to submission field values" # TODO: I18n
    opt
  end

  # lookup_commit_button
  #
  # @param [String] label
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def lookup_commit_button(label: nil, css: '.commit', **opt)
    label       ||= 'Update' # TODO: I18n
    opt[:type]  ||= 'submit'
    opt[:title] ||= 'Replace submission field values with these changes' # TODO: I18n
    prepend_css!(opt, css)
    html_button(label, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Methods called by #lookup_container.
  #
  # @type [Array<Symbol>]
  #
  LOOKUP_PARTS = %i[
    lookup_in_progress
    lookup_query
    lookup_input
    lookup_status
    lookup_results
  ].freeze

  # The content element of the bibliographic lookup popup.
  #
  # @param [String] unique          Default: `#hex_rand`.
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the outermost #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @note This does not address dynamic results entries.
  #
  # @see file:app/assets/javascripts/shared/lookup-modal.js *LookupModal*
  #
  def lookup_container(unique: nil, css: '.lookup-container', **opt)
    unique ||= hex_rand
    prepend_css!(opt, css)
    html_div(opt) do
      LOOKUP_PARTS.map { |meth| send(meth, unique: unique) }
    end
  end

  # Display of lookup query terms.
  #
  # @param [String] unique          Ignored
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/lookup-modal.js *queryPanel*
  #
  def lookup_query(unique: nil, css: '.lookup-query', **opt)
    unique # NOTE: unused
    label  = 'Query' # TODO: I18n
    label  = html_tag(:label, label)
    terms  = html_div(class: 'terms')
    prepend_css!(opt, css)
    html_div(opt) do
      label << terms
    end
  end

  # Input prompt for lookup query terms.
  #
  # @param [String] unique
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/lookup-modal.js *inputPrompt*
  #
  def lookup_input(unique: nil, css: '.lookup-prompt', **opt)
    uniq_opt     = { unique: unique || hex_rand }

    # == Lookup query terms input
    lookup_label = 'Lookup' # TODO: I18n
    terms_label  = 'Query'  # TODO: I18n
    terms_css    = 'item-terms'
    terms_id     = unique_id(terms_css, **uniq_opt)
    terms_input  =
      html_div(class: terms_css) do
        label  = h.label_tag(terms_id, "#{terms_label}:")
        input  = h.text_field_tag('terms', nil, id: terms_id)
        button = html_button(lookup_label, class: 'submit')
        label << input << button
      end

    # == Separator type radio buttons
    separator_label = 'Term Separators' # TODO: I18n
    separator_css   = 'item-separator'
    separator_id    = unique_id(separator_css, **uniq_opt)
    separators = {
      space: 'Space, tab, and <strong>|</strong> (pipe)'.html_safe,
      pipe:  'Only <strong>|</strong> (pipe)'.html_safe
    }
    selected = :space
    separator_choices =
      html_tag(:fieldset, id: separator_id, class: separator_css) do
        name = 'separator'
        separators.map.with_index { |(value, text), index|
          id      = "#{separator_id}-#{index}"
          checked = selected ? (value == selected) : index.zero?
          button  = h.radio_button_tag(name, value, checked, id: id)
          label   = h.label_tag(id, text)
          button << label
        }.unshift(html_tag(:legend, separator_label))
      end

    # == Input prompt element
    prepend_css!(opt, css)
    html_div(opt) do
      terms_input << separator_choices
    end
  end

  # Container for lookup statuses.
  #
  # @param [String] unique          Ignored
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/lookup-modal.js *statusDisplay*
  #
  def lookup_status(unique: nil, css: '.lookup-status', **opt)
    unique # NOTE: unused
    label  = 'Searching:' # TODO: I18n
    status = html_div(class: 'services invisible') { html_tag(:label, label) }
    notice = html_div(class: 'notice')
    prepend_css!(opt, css)
    html_div(opt) do
      status << notice
    end
  end

  # Container for lookup raw output, errors, and diagnostics.
  #
  # @param [String] unique
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/lookup-modal.js *outputDisplay*
  #
  def lookup_results(unique: nil, css: '.lookup-output', **opt)
    uniq_opt  = { unique: unique || hex_rand }

    # == Output display heading
    hdg_label = 'Results' # TODO: I18n
    hdg_css   = 'lookup-heading'
    hdg_id    = unique_id(hdg_css, **uniq_opt)
    heading   = html_tag(2, hdg_label, id: hdg_id, class: hdg_css)

    # == Output results element
    res_css   = 'item-results'
    res_id    = unique_id(res_css, **uniq_opt)
    res_opt   = { 'aria-labelledby': hdg_id, class: "#{res_css} value" }
    results   = h.text_area_tag(res_id, nil, res_opt)

    # == Output errors element
    err_label = 'Errors' # TODO: I18n
    err_css   = 'item-errors'
    err_id    = unique_id(err_css, **uniq_opt)
    errors    =
      html_div(class: 'pair') do
        label   = h.label_tag(err_id, err_label, class: 'label')
        display = h.text_area_tag(err_id, nil, class: "#{err_css} value")
        label << display
      end

    # == Output diagnostics element
    diag_label  = 'Diagnostics' # TODO: I18n
    diag_css    = 'item-diagnostics'
    diag_id     = unique_id(diag_css, **uniq_opt)
    diagnostics =
      html_div(class: 'pair') do
        label   = h.label_tag(diag_id, diag_label, class: 'label')
        display = h.text_area_tag(diag_id, nil, class: "#{diag_css} value")
        label << display
      end

    # == Output display body
    prepend_css!(opt, css)
    output =
      html_div(opt) do
        results << errors << diagnostics
      end

    # == Output heading and display elements
    heading << output
  end

  # Initially hidden in-progress overlay.
  #
  # @param [String] unique          Ignored
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def lookup_in_progress(unique: nil, css: '.loading-in-progress', **opt)
    unique # NOTE: unused
    prepend_css!(opt, css, 'hidden')
    html_div(opt) do
      html_div(class: 'content')
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
