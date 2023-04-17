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

  public

  # Request header values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def request_headers_section(**opt)
    hdrs = []

    # From ActionDispatch::Request
    hdrs += ActionDispatch::Request::ENV_METHODS
    hdrs += %w(ORIGINAL_FULLPATH SERVER_SOFTWARE RAW_POST_DATA)
    hdrs += %w(HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION)
    hdrs += %w(REDIRECT_X_HTTP_AUTHORIZATION HTTP_X_REQUESTED_WITH)

    # From ActionDispatch::Http::Cache::Request
    hdrs += %w(HTTP_IF_MODIFIED_SINCE HTTP_IF_NONE_MATCH)
    hdrs += %w(Last-Modified Date)

    # From Rack
    hdrs += %w(HTTP_HOST HTTP_PORT PATH_INFO SERVER_PORT)
    hdrs += %w(REQUEST_METHOD REQUEST_PATH QUERY_STRING SCRIPT_NAME)
    hdrs += %w(Cache-Control Expires Content-Length Content-Type)
    hdrs += %w(Transfer-Encoding ETag)
    hdrs += %w(HTTP_COOKIE Set-Cookie)

    # From Rack::Request
    hdrs += string_constants(Rack::Request, 'HTTP_')
    hdrs += %w(CONTENT_LENGTH HTTP_USER_AGENT HTTP_REFERER)

    hdrs.sort!.uniq!
    hdrs = [*hdrs.partition { |v| v.match?(/[a-z]/) }]

    dt_dd_section(hdrs, **opt)
  end

  # Rails header values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def rails_headers_section(**opt)
    hdrs = %w(
      action_controller.instance
      action_dispatch.content_security_policy
      action_dispatch.content_security_policy_nonce
      action_dispatch.content_security_policy_nonce_directives
      action_dispatch.content_security_policy_nonce_generator
      action_dispatch.content_security_policy_report_only
      action_dispatch.encrypted_cookie_salt
      action_dispatch.encrypted_signed_cookie_salt
      action_dispatch.exception
      action_dispatch.http_auth_salt
      action_dispatch.logger
      action_dispatch.original_path
      action_dispatch.parameter_filter
      action_dispatch.permissions_policy
      action_dispatch.redirect_filter
      action_dispatch.remote_ip
      action_dispatch.request.parameters
      action_dispatch.request.path_parameters
      action_dispatch.request_id
      action_dispatch.routes
      action_dispatch.show_detailed_exceptions
      action_dispatch.show_exceptions
    )
    hdrs += string_constants(ActionDispatch::Cookies)
    hdrs += string_constants(ActionDispatch::ContentSecurityPolicy::Request)
    hdrs.delete('Set-Cookie')
    hdrs.sort!.uniq!
    dt_dd_section(hdrs, **opt)
  end

  # Rack header values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def rack_headers_section(**opt)
    hdrs  = string_constants(Rack, 'RACK_')
    hdrs -= %w(rack.input rack.session rack.session.options)
    hdrs.sort!.uniq!
    dt_dd_section(hdrs, **opt)
  end

  # Request `session` values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def request_session_section(**opt)
    dt_dd_section(request.session.to_hash, **opt)
  end

  # Request `session_options` values listing.
  #
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def request_options_section(**opt)
    dt_dd_section(request.session_options.to_hash, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Translate Hash keys and values into an element containing pairs of
  # dt and dd elements.
  #
  # @param [Array, Hash] hdrs
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dt_dd_section(hdrs, css: '.pairs', **opt)
    opt.reverse_merge!('data-turbolinks-cache': false)
    prepend_css!(opt, css)
    html_div(opt) do
      # noinspection RubyMismatchedArgumentType
      dt_dd_lines(hdrs)
    end
  end

  # Translate Hash keys and values into pairs of dt and dd elements.
  #
  # @param [Array, Hash] hdrs
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def dt_dd_lines(hdrs)
    if hdrs.is_a?(Array)
      hash = hdrs.flatten.map { |hdr| [hdr, request.get_header(hdr)] }.to_h
    else
      hash = hdrs
    end
    # noinspection RubyMismatchedArgumentType
    dt_dd_pairs(hash).join("\n").html_safe
  end

  # Translate Hash keys and values into pairs of dt and dd elements.
  #
  # @param [Hash] hash
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def dt_dd_pairs(hash)
    hash.map do |k, v|
      css   = (v.present? || false?(v)) ? 'present' : 'blank'
      opt   = { class: css }
      label = html_tag(:dt, k, opt)
      value = html_tag(:dd, opt) { html_div(v.inspect, class: 'value') }
      label << value
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Return the values of the constants defined in the class or module which
  # are strings.
  #
  # @param [Module]              mod
  # @param [String, Regexp, nil] matching
  #
  # @return [Array<String>]
  #
  def string_constants(mod, matching = nil)
    mod.constants.map { |constant|
      case matching
        when String then next unless constant.start_with?(matching)
        when Regexp then next unless constant.to_s.match?(matching)
      end
      value = mod.const_get(constant)
      value if value.is_a?(String)
    }.compact
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
