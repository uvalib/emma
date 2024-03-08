# app/helpers/session_debug_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper support methods related to `#session`.
#
module SessionDebugHelper

  include DevHelper
  include GridHelper
  include IdentityHelper
  include ParamsHelper
  include SysHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether on-screen debugging is applicable.
  #
  # @param [Symbol,String,nil] controller   Controller-specific debugging.
  #
  def session_debug?(controller = nil)
    dev     = developer?
    local   = not_deployed?
    setting =
      if controller
        session["app.#{controller}.debug"]
      elsif local || dev
        session['app.debug']
      end
    if local && dev || dev_client?
      !false?(setting)  # Debugging *on* by default.
    else
      true?(setting)    # Debugging *off* by default.
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Session keys that are not reported in the session debug table.
  #
  # @type [Array<String>]
  #
  SESSION_SKIP_KEYS = %w[_csrf_token warden.user.user.key].freeze

  # Request headers that are not reported in the session debug table.
  #
  # @type [Array<String>]
  #
  REQUEST_SKIP_HDRS = %w[GATEWAY_INTERFACE HTTP_COOKIE].freeze

  # Render a table of values from `#session`.
  #
  # @param [Boolean] extended         If *true* show request headers.
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #debug_table.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def session_debug_table(extended: false, css: '.session-debug', **opt)
    table = { SESSION: :VALUE }
    table[:id] = request.session_options[:id]
    session.to_hash.except!(*SESSION_SKIP_KEYS).each do |k, v|
      if compressed_value?(v)
        v = decompress_value(v)
        v = ERB::Util.h(v.inspect) << html_span('[compressed]', class: 'note')
      end
      table[k] = v
    end
    if extended
      table.merge!(REQUEST: :VALUE)
      request_headers_names.excluding(*REQUEST_SKIP_HDRS).each do |k|
        v = request.get_header(k)
        table[k] = v if v.present? || v.is_a?(FalseClass)
      end
    end
    table.transform_values! do |v|
      if v.is_a?(ActiveSupport::SafeBuffer)
        v
      elsif v.is_a?(Symbol)
        v.to_s
      elsif !v.respond_to?(:to_hash)
        v.inspect
      else
        v.to_hash.inspect.sub(/^{(.*)}$/, '{ \1 }').gsub(/=>/, ' \0 ')
      end
    end
    prepend_css!(opt, css)
    debug_table(table, **opt)
  end

  # Show data-* attributes used within the page.
  # @private
  DEBUG_DATA_ATTR = true

  # Show CSS classes used within the page.
  # @private
  DEBUG_CSS_CLASS = false

  # Footer debug values which may be filled by client-side logic.
  #
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #debug_table.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                     If the section would be empty.
  #
  # @see file:javascripts/feature/client-debug.js
  #
  def client_debug_table(css: '.client-debug', **opt)
    table = {}
    table.merge!('data-*': nil) if DEBUG_DATA_ATTR
    table.merge!(class:    nil) if DEBUG_CSS_CLASS
    return if table.empty?
    table.reverse_merge!(CLIENT: :VALUE)
    prepend_css!(opt, css)
    debug_table(table, **opt)
  end

  # Render a table of values within the footer '.page-debug'.
  #
  # @param [Hash]   pairs             Key-value pairs to display.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def debug_table(pairs, css: '.debug-table', **opt)
    prepend_css!(opt, css)
    grid_table(pairs, **opt)
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
