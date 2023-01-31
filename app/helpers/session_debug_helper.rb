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
  include ParamsHelper
  include RoleHelper

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
  SESSION_SKIP_KEYS = %w(_csrf_token warden.user.user.key)

  # Render a table of values from `#session`.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def session_debug(css: '.session-debug-table', **opt)
    table = { SESSION: 'DEBUG' }
    pairs =
      session.to_hash.except!(*SESSION_SKIP_KEYS).transform_values! do |v|
        if compressed_value?(v)
          v = decompress_value(v)
          ERB::Util.h(v.inspect) << html_span('[compressed]', class: 'note')
        else
          v = v.to_hash if v.respond_to?(:to_hash)
          v.inspect.sub(/^{(.*)}$/, '{ \1 }').gsub(/=>/, ' \0 ')
        end
      end
    table.merge!(pairs)
    prepend_css!(opt, css)
    grid_table(table, **opt)
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
