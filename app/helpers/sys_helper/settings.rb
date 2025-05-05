# app/helpers/sys_helper/settings.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Settings

  include SysHelper::Common
  include Emma::Json

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include ActionView::Helpers::FormTagHelper
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  COMMIT_LABEL = config_term(:sys, :commit).freeze

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
        ExecutionProperty.instance_methods(false).sort.map do |meth|
          app_setting_display(meth, ExecutionProperty.send(meth))
        end
      end
    end
  end

  # Display of ApiService engine setting values.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #form_tag
  #
  def app_engines(css: '.field-container.list', **opt)
    services = ApiService.services.map { [_1.service_name, _1.engines] }
    services = services.sort_by { _1 }.to_h
    engines  = services.extract!('search', 'ingest').merge(services)
    prepend_css!(opt, css)
    html_div(**opt) do
      html_div(class: 'fields') do
        engines.map { app_entry_display(_1, _2) }
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
      src   = value.origin
      value = value.content
    else
      src   = (:env unless value.nil?)
    end

    cls = []
    tip = []
    tip << :no_env_var    unless %i[env cred yaml].include?(src)
    tip << :"from_#{src}" if src
    cls << "from-#{src}"  if src
    tip.map! { config_term(:sys, _1) }
    if value.nil? || (value == EMPTY_VALUE)
      cls << 'missing'
    elsif !boolean?(value)
      cls << 'invalid'
      tip << config_term(:sys, :invalid_value, value: value.inspect)
    end
    tip  = tip.join('; ').presence&.upcase_first
    cls  = css_classes('radio-group line', *cls)

    src  = app_origin_marker(src)
    name = html_div(key, title: tip, class: cls)
    on   = app_flag_radio_button(key, value, on: true)
    off  = app_flag_radio_button(key, value, on: false)

    src << name << on << off
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
      src   = value.origin
      value = value.content
    else
      src   = (:env unless value.nil?)
    end

    cls = []
    tip = []
    tip << :no_env_var    unless %i[env cred yaml].include?(src)
    tip << :"from_#{src}" if src
    cls << "from-#{src}"  if src
    tip.map! { config_term(:sys, _1) }

    app_entry_display(key, value, src, class: cls, title: tip)
  end

  # HTML for an entry displaying an application setting value.
  #
  # @param [Symbol, String]          key
  # @param [any, nil]                value
  # @param [Symbol,String,false,nil] src
  # @param [Hash]                    opt    Passed to label and value elements.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_entry_display(key, value, src = false, **opt)
    case value
      when Hash        then append_css!(opt, 'hierarchy')
      when nil         then append_css!(opt, 'text missing')
      when EMPTY_VALUE then append_css!(opt, 'text missing')
      when 'nil'       then append_css!(opt, 'text literal')
      when String      then append_css!(opt, 'text string')
      else                  append_css!(opt, 'text literal')
    end
    opt[:title] = opt[:title].join('; ') if opt[:title].is_a?(Array)
    opt[:title] = opt[:title]&.upcase_first

    id    = css_randomize(key)
    l_id  = "label-#{id}"
    v_id  = "value-#{id}"

    src   = app_origin_marker(src)

    l_opt = prepend_css(opt, 'setting line').merge!(id: l_id)
    label = html_span(**l_opt) { key }

    v_opt = prepend_css(opt,'value').merge!(id: v_id, 'aria-describedby': l_id)
    value = html_div(**v_opt) { app_value_display(value) }

    src << label << value
  end

  # Render a value for display in an application setting entry.
  #
  # @param [any, nil] value
  #
  # @return [ActiveSupport::SafeBuffer] If *value* is a Hash
  # @return [String]                    Otherwise
  #
  def app_value_display(value)
    value = EMPTY_VALUE  if value.nil? || (value == :null)
    return value         if (value == EMPTY_VALUE) || (value == 'nil')
    return value.inspect unless value.is_a?(Hash)
    value.flat_map { |k, v|
      { name: k, value: app_value_display(v) }.map do |cls, val|
        html_div(val, class: cls)
      end
    }.join(' ').html_safe
  end

  # Create a radio button and label for an EMMA flag.
  #
  # @param [Symbol, String] flag
  # @param [any, nil]       value     Current value of the flag.
  # @param [Boolean, nil]   on        Whether this is the 'ON' or 'OFF' control
  # @param [Hash]           opt       Passed to button and label elements.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_flag_radio_button(flag, value, on:, **opt)
    css_cls = ('on' if on == true) || ('off' if on == false)
    prepend_css!(opt, css_cls)
    checked = on ? true?(value) : false?(value)
    control = radio_button_tag(flag, on, checked, opt)
    label   = config_term(on ? :_on : :_off).upcase
    label   = label_tag(flag, label, opt.merge(value: on))
    control << label
  end

  # Create a marker element indicating the origin of a value.
  #
  # @param [Symbol,String,Boolean,nil] src
  # @param [String]                    css  Characteristic CSS class/selector.
  # @param [Hash]                      opt  Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_origin_marker(src, css: '.origin', **opt)
    return src       if src.is_a?(ActiveSupport::SafeBuffer)
    return html_span if src.is_a?(FalseClass)
    src = nil        if src.is_a?(TrueClass)
    prepend_css!(opt, "from-#{src}") if src
    prepend_css!(opt, css)
    html_span(src, **opt)
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
