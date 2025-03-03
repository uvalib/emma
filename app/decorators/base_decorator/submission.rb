# app/decorators/base_decorator/submission.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting bulk submission.
#
module BaseDecorator::Submission

  include BaseDecorator::Common
  include BaseDecorator::Configuration

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  ACTION_ATTR = BaseDecorator::Controls::ACTION_ATTR

  # The CSS class selector associated with the button for displaying the
  # usually-hidden submission modal.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/modal-dialog.js ModalDialog.SELECTOR_ATTR
  #
  MONITOR_CLASS = '.monitor-popup'

  # The JavaScript ModalDialog subclass for the bulk submission monitor popup.
  #
  # @type [String]
  #
  # @see file:javascripts/shared/modal-dialog.js ModalDialog.CLASS_ATTR
  # @see file:javascripts/shared/submit-modal.js SubmitModal
  #
  MONITOR_JS_CLASS = 'SubmitModal'

  # @private
  # @type [Hash{Symbol=>String}]
  SUBMIT_TERMS = config_term_section(:submission, :monitor).deep_freeze

  SUBMIT_TITLE      = SUBMIT_TERMS[:title]
  SUBMIT_DESC       = SUBMIT_TERMS[:description]
  SUBMIT_CLOSE      = SUBMIT_TERMS[:close]
  SUBMIT_SUCCESSES  = SUBMIT_TERMS[:successes]
  SUBMIT_FAILURES   = SUBMIT_TERMS[:failures]
  SUBMIT_MESSAGES   = SUBMIT_TERMS[:messages]
  SUBMIT_ERRORS     = SUBMIT_TERMS[:errors]
  SUBMIT_DIAG       = SUBMIT_TERMS[:diagnostics]
  SUBMIT_DIAG_TIP   = SUBMIT_TERMS[:diagnostics_tip]

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A control which engages #monitor_modal display.
  #
  # In addition to creating the control, this method also adds the modal to
  # the page modals (unless it already has been added).
  #
  # @param [String] js                ModalDialog subclass.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #monitor_modal except for:
  #
  # @option opt [Hash]          :button         To #monitor_button_options.
  # @option opt [Symbol]        :type           Passed to #make_popup_toggle.
  # @option opt [Symbol,String] :'data-action'  Passed to #make_popup_toggle.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see LayoutHelper::PageModals#add_page_modal
  #
  def monitor_control(js: MONITOR_JS_CLASS, css: MONITOR_CLASS, **opt)
    trace_attrs!(opt, __method__)
    t_opt = trace_attrs_from(opt)
    type  = opt.delete(:type)
    m_opt = { 'data-modal-class': js, 'data-modal-selector': css }
    b_opt = opt.extract!(ACTION_ATTR).merge!(opt.delete(:button) || {})
    b_opt = monitor_button_options(**b_opt, **m_opt, **t_opt)
    h.add_page_modal(css) { monitor_modal(**opt, **m_opt) }
    h.make_popup_toggle(button: b_opt, type: type, **t_opt)
  end

  # A modal popup for viewing submission communication details.
  #
  # @param [Hash]   container       Options for #lookup_container.
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt             Passed to #modal_popup except for:
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def monitor_modal(container: {}, css: MONITOR_CLASS, **opt)
    opt[:close]        = monitor_cancel_options
    opt[:controls]     = monitor_log_toggle
    opt[:'aria-label'] = SUBMIT_DESC
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    h.modal_popup(**opt) do
      t_opt = trace_attrs_from(opt)
      monitor_container(**container, **t_opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The options to create a toggle button for the submission monitor popup.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @option opt [Hash] :label         Override the default button label.
  #
  # @return [Hash]
  #
  # @see PopupHelper#inline_popup
  #
  def monitor_button_options(css: '.monitor-button', **opt)
    prepend_css!(opt, css)
  end

  # monitor_cancel_options
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def monitor_cancel_options(**opt)
    opt[:label] ||= SUBMIT_CLOSE
    opt
  end

  # A control for showing/hiding processing details on the submission monitor
  # popup.
  #
  # @param [String] label
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def monitor_log_toggle(label: nil, css: '.log-toggle', **opt)
    label       ||= SUBMIT_DIAG
    opt[:title] ||= SUBMIT_DIAG_TIP
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    html_button(label, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Methods called by #monitor_container.
  #
  # @type [Array<Symbol>]
  #
  MONITOR_PARTS = %i[
    monitor_heading
    monitor_status
    monitor_output
    monitor_log
  ].freeze

  # The content element of the bulk submission monitor popup.
  #
  # @param [String] unique            Default: `#hex_rand`.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to the outermost #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/submit-modal.js *SubmitModal*
  #
  def monitor_container(unique: nil, css: '.monitor-container', **opt)
    unique ||= hex_rand
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    html_div(**opt) do
      t_opt = trace_attrs_from(opt)
      MONITOR_PARTS.map { send(_1, unique: unique, **t_opt) }
    end
  end

  # monitor_heading
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def monitor_heading(unique:, css: '.monitor-heading', **opt)
    opt[:id] = unique_id(css, unique: unique)
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    html_h1(SUBMIT_TITLE, **opt)
  end

  # monitor_status
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/submit-modal.js *statusDisplay*
  #
  def monitor_status(css: '.monitor-status', **opt)
    opt.delete(:unique)
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    html_div(**opt) do
      t_opt = trace_attrs_from(opt)
      html_div(class: 'notice', **t_opt)
    end
  end

  # monitor_output
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def monitor_output(css: '.monitor-output', **opt)
    trace_attrs!(opt, __method__)
    t_opt = trace_attrs_from(opt)
    opt.delete(:unique)

    # === Successes element
    successes = output_part(SUBMIT_SUCCESSES, css: 'success', **t_opt)

    # === Failures element
    failures = output_part(SUBMIT_FAILURES, css: 'failure', **t_opt)

    # === Output display body
    prepend_css!(opt, css)
    html_div(**opt) do
      successes << failures
    end
  end

  # output_part
  #
  # @param [String] label
  # @param [String] css
  # @param [Hash]   opt               Passed to the outermost #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def output_part(label, css:, **opt)
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css)
    html_div(**opt) do
      t_opt = trace_attrs_from(opt)
      html_h2(label, **t_opt) << html_div(class: 'display', **t_opt)
    end
  end

  # Container for bulk submission raw output, errors, and diagnostics.
  #
  # @param [String]  unique
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to the outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/shared/submit-modal.js *outputDisplay*
  #
  def monitor_log(unique:, css: '.monitor-log', **opt)
    trace_attrs!(opt, __method__)
    t_opt = trace_attrs_from(opt)

    # === Results element
    res = log_part(SUBMIT_MESSAGES, type: :results, unique: unique, **t_opt)

    # === Errors element
    err = log_part(SUBMIT_ERRORS, type: :errors, unique: unique, **t_opt)

    # === Diagnostics element
    dia = log_part(SUBMIT_DIAG, type: :diagnostics, unique: unique, **t_opt)

    # === Log display body
    prepend_css!(opt, css)
    html_div(**opt) do
      res << err << dia
    end
  end

  # log_part
  #
  # @param [String] label
  # @param [Symbol] type
  # @param [String] unique
  # @param [Hash]   opt               Passed to the input area.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def log_part(label, type:, unique:, **opt)
    trace_attrs!(opt, __method__)
    t_opt = trace_attrs_from(opt)
    id    = unique_id(type, unique: unique)
    html_div(class: "#{type} pair", **t_opt) do
      lbl_opt = { class: 'label', **t_opt }
      prepend_css!(opt, "item-#{type}", 'value')
      h.label_tag(id, label, lbl_opt) << h.text_area_tag(id, nil, opt)
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
