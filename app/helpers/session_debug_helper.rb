# app/helpers/session_debug_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods related to `#session`.
#
module SessionDebugHelper

  def self.included(base)
    __included(base, '[SessionDebugHelper]')
  end

  include ParamsHelper
  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether on-screen debugging is applicable.
  #
  def session_debug?
    on_by_default   = !application_deployed?
    current_setting = session['debug']
    on_by_default ? !false?(current_setting) : true?(current_setting)
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
    pairs =
      session.to_hash.except!(*SESSION_SKIP_KEYS).transform_values! do |v|
        if compressed_value?(v)
          v = decompress_value(v)
          h(v.inspect) << html_span('[compressed]', class: 'note')
        else
          v.inspect.sub(/^{(.*)}$/, '{ \1 }').gsub(/=>/, ' \0 ')
        end
      end
    table = { SESSION: 'DEBUG' }.merge(pairs)
    opt   = prepend_css_classes(opt, 'session-debug-table')
    grid_table(table, **opt)
  end

end

__loading_end(__FILE__)
