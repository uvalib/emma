# app/helpers/sys_helper/settings.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Settings

  include SysHelper::Common

  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActionView::Helpers::FormTagHelper
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private # TODO: I18n
  COMMIT_LABEL = 'Commit'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # On/off toggles for each application setting flag.
  #
  # @param [String] submit            The submit label (or button).
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #form_tag
  #
  def app_flags(submit: nil, css: '.field-container.form', **opt)
    submit = submit_tag(submit || COMMIT_LABEL) unless submit&.html_safe?
    prepend_css!(opt, css)
    form_tag(update_sys_path, **opt) do
      html_fieldset(nil, class: 'fields') do
        AppSettings.each_flag(spacers: true).map do |name, value|
          value.spacer ? app_spacer : app_flag_controls(name, value)
        end
      end << submit
    end
  end

  # Display of application setting values.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #form_tag
  #
  def app_settings(css: '.field-container.list', **opt)
    prepend_css!(opt, css)
    html_div(**opt) do
      html_div(class: 'fields') do
        AppSettings.each_setting(spacers: true).map do |name, value|
          value.spacer ? app_spacer : app_setting_display(name, value)
        end
      end
    end
  end

  # Display of application GlobalProperty values.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #form_tag
  #
  def app_properties(css: '.field-container.list', **opt)
    prepend_css!(opt, css)
    html_div(**opt) do
      html_div(class: 'fields') do
        GlobalProperty.instance_methods.map do |meth|
          app_setting_display(meth, Object.send(meth))
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # HTML for separating application configuration items.
  #
  # @param [String, nil] content
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_spacer(content = nil)
    html_div(content, class: 'spacer', 'aria-hidden': true)
  end

  # HTML for a labelled pair of radio buttons for turning a flag on/off.
  #
  # @param [Symbol, String]                   key
  # @param [AppSettings::Value, Boolean, nil] value   Current value of the flag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_flag_controls(key, value = nil)
    value = AppSettings[key] if value.nil?
    if value.is_a?(AppSettings::Value)
      env, obj = value.env?, value.obj?
      case
        when env then value = value.env
        when obj then value = value.obj
        else          value = nil
      end
    else
      env, obj = !value.nil?
    end

    cls = []
    tip = []
    if env
      cls << 'from-env'
      tip << 'from ENV variable' # TODO: I18n
    else
      tip << 'ENV variable not present' # TODO: I18n
    end
    if obj
      cls << 'from-obj'
      tip << 'value from constant' # TODO: I18n
    end
    if value.nil? || (value == EMPTY_VALUE)
      cls << 'missing'
    elsif !boolean?(value)
      cls << 'invalid'
      tip << "invalid value #{value.inspect}" # TODO: I18n
    end

    opt  = { class: css_classes('radio-group line', *cls) }
    opt[:title] = tip.join('; ').upcase_first if tip.present?

    name = html_div(key, **opt)
    on   = app_flag_radio_button(key, value, on: true)
    off  = app_flag_radio_button(key, value, on: false)

    name << on << off
  end

  # HTML for an entry displaying an application configuration value.
  #
  # @param [Symbol, String]                  key
  # @param [AppSettings::Value, String, nil] value
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_setting_display(key, value = nil)
    value = AppSettings[key] if value.nil?
    if value.is_a?(AppSettings::Value)
      env, obj = value.env?, value.obj?
      case
        when env then value = value.env
        when obj then value = value.obj
        else          value = nil
      end
    else
      env, obj = !value.nil?
    end

    cls = []
    tip = []
    if env
      cls << 'from-env'
      tip << 'from ENV variable' # TODO: I18n
    else
      tip << 'ENV variable not present' # TODO: I18n
    end
    if obj
      cls << 'from-obj'
      tip << 'value from constant' # TODO: I18n
    end
    case value
      when nil         then cls << 'missing'; value = EMPTY_VALUE
      when EMPTY_VALUE then cls << 'missing'
      when 'nil'       then cls << 'literal'
      when String      then cls << 'string';  value = value.inspect
      else                  cls << 'literal'; value = value.inspect
    end

    id    = css_randomize(key)
    v_id  = "value-#{id}"
    l_id  = "label-#{id}"
    opt   = { class: css_classes(cls) }
    opt[:title] = tip.join('; ').upcase_first if tip.present?

    l_opt = prepend_css(opt, 'setting line').merge!(id: l_id)
    label = html_span(key, **l_opt)

    v_opt = prepend_css(opt, 'text').merge!(id: v_id, 'aria-describedby': l_id)
    value = html_div(value, **v_opt)

    label << value
  end

  # Create a radio button and label for an EMMA flag.
  #
  # @param [Symbol, String] flag
  # @param [*]              value     Current value of the flag.
  # @param [Boolean, nil]   on        Whether this is the 'ON' or 'OFF' control
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_flag_radio_button(flag, value, on:)
    checked = on ? true?(value) : false?(value)
    label   = on ? 'ON'         : 'OFF' # TODO: I18n
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
