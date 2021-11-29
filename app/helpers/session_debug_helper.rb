# app/helpers/session_debug_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper support methods related to `#session`.
#
module SessionDebugHelper

  include ParamsHelper
  include HtmlHelper
  include RoleHelper
  include DevHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether on-screen debugging is applicable.
  #
  def session_debug?
    dev           = developer?
    local         = !application_deployed?
    on_by_default = local && dev || dev_client?
    setting       = (session['app.debug'] if local || dev)
    on_by_default ? !false?(setting) : true?(setting)
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
  # @param [Hash] opt                 Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def session_debug(**opt)
    css_selector = '.session-debug-table'
    table = { SESSION: 'DEBUG' }
    pairs =
      session.to_hash.except!(*SESSION_SKIP_KEYS).transform_values! do |v|
        if compressed_value?(v)
          v = decompress_value(v)
          h(v.inspect) << html_span('[compressed]', class: 'note')
        else
          v = v.to_hash if v.respond_to?(:to_hash)
          v.inspect.sub(/^{(.*)}$/, '{ \1 }').gsub(/=>/, ' \0 ')
        end
      end
    table.merge!(pairs)
    prepend_classes!(opt, css_selector)
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
