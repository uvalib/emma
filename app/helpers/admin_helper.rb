# app/helpers/admin_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module AdminHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HTML for a labelled pair of radio buttons for turning a flag on/off.
  #
  # @param [Symbol, String] key
  # @param [Boolean, nil]   value     Current value of the flag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_flag_radio_buttons(key, value = nil)
    value  = AppSettings[key] if value.nil?
    name   = key.to_s
    label  = label_tag(name, name, class: 'radio-group line')
    check1 = emma_flag_checkbox(name, value, on: true)
    check2 = emma_flag_checkbox(name, value, on: false)
    label << check1 << check2
  end

  # HTML for an entry displaying an application configuration value.
  #
  # @param [Symbol, String] key
  # @param [String, nil]    value     Current value of the flag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_setting_display(key, value = nil)
    value = AppSettings[key] if value.nil?
    value = nil if value == 'nil'
    empty = value.nil?
    value = value.inspect
    name  = key.to_s
    v_id  = css_randomize(name)
    l_id  = "label-#{v_id}"

    l_opt = { id: l_id, class: 'setting line' }
    append_css!(l_opt, value)       if empty
    append_css!(l_opt, 'condensed') if name.size > 25
    label = html_span(name, l_opt)

    v_opt = { id: v_id, class: 'text', 'aria-describedby': l_id }
    append_css!(v_opt, value) if empty
    value = html_div(value, v_opt)

    label << value
  end

  # HTML for separating application configuration items.
  #
  # @param [String, nil] content
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_spacer(content = nil)
    html_div(content, class: 'spacer', 'aria-hidden': true)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create a radio button and label for an EMMA flag.
  #
  # @param [Symbol, String] flag
  # @param [Boolean, nil]   value     Current value of the flag.
  # @param [Boolean]        on        Whether this is the 'ON' or 'OFF' control
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emma_flag_checkbox(flag, value, on:)
    checked = on ? !!value : !value
    label   = on ? 'ON'    : 'OFF' # TODO: I18n
    control = radio_button_tag(flag, on, checked)
    label   = label_tag(flag, label, value: on)
    control << label
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
