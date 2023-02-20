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
    type  = opt.delete(:type)
    m_opt = { 'data-modal-class': js, 'data-modal-selector': css }
    b_opt = extract_hash!(opt, ACTION_ATTR).merge!(opt.delete(:button) || {})
    b_opt = monitor_button_options(**b_opt, **m_opt)
    h.add_page_modal(css) { monitor_modal(**opt, **m_opt) }
    h.make_popup_toggle(button: b_opt, type: type)
  end

  # A modal popup for viewing submission communication details.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #modal_popup except for:
  #
  # @option opt [Hash] :container     Options for #monitor_container.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def monitor_modal(css: MONITOR_CLASS, **opt)
    c_opt = opt.delete(:container) || {}
    opt[:close]    = monitor_cancel_options
    opt[:controls] = monitor_log_toggle
    prepend_css!(opt, css)
    h.modal_popup(**opt) do
      monitor_container(**c_opt)
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
    opt[:label] ||= 'Close' # TODO: I18n
    opt
  end

  # monitor_log_toggle
  #
  # @param [String] label
  # @param [String] css             Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def monitor_log_toggle(label: nil, css: '.log-toggle', **opt)
    label       ||= 'Diagnostics' # TODO: I18n
    opt[:title] ||= 'View WebSocket communications' # TODO: I18n
    prepend_css!(opt, css)
    html_button(label, opt)
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
    prepend_css!(opt, css)
    html_div(opt) do
      MONITOR_PARTS.map { |meth| send(meth, unique: unique) }
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
    label    = 'Bulk Submission Monitor' # TODO: I18n
    opt[:id] = unique_id(css, unique: unique)
    prepend_css!(opt, css)
    html_tag(:h1, label, opt)
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
    notice = html_div(class: 'notice')
    prepend_css!(opt, css)
    html_div(opt) do
      notice
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
    opt.delete(:unique)

    # == Successes element
    successes = 'Submitted Items' # TODO: I18n
    successes = output_part(successes, css: 'success')

    # == Failures element
    failures = 'Submission Errors' # TODO: I18n
    failures = output_part(failures, css: 'failure')

    # == Output display body
    prepend_css!(opt, css)
    html_div(opt) do
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
    prepend_css!(opt, css)
    html_div(opt) do
      html_tag(:h2, label) << html_div(class: 'display')
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

    # == Results element
    res = 'Messages' # TODO: I18n
    res = log_part(res, type: :results, unique: unique)

    # == Errors element
    err = 'Errors' # TODO: I18n
    err = log_part(err, type: :errors, unique: unique)

    # == Diagnostics element
    dia = 'Diagnostics' # TODO: I18n
    dia = log_part(dia, type: :diagnostics, unique: unique)

    # == Log display body
    prepend_css!(opt, css)
    html_div(opt) do
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
    id = unique_id(type, unique: unique)
    html_div(class: "#{type} pair") do
      prepend_css!(opt, "item-#{type}", 'value')
      h.label_tag(id, label, class: 'label') << h.text_area_tag(id, nil, opt)
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