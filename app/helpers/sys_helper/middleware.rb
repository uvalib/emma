# app/helpers/sys_helper/middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Middleware

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table of ActionDispatch::MiddlewareStack entries.
  #
  # @param [Boolean] sort
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #sys_table.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def application_middleware(sort: false, css: '.middleware-table', **opt)
    anon  = 0
    pairs =
      Rails.configuration.middleware.middlewares.map do |obj|
        key   = obj.name.to_s.presence || "anonymous #{anon += 1}"
        id    = obj.object_id
        args  = obj.args&.inspect&.sub(/^\[(.*)\]$/, '\1')&.presence
        block = obj.block
        entry = [id, args, block].map! { |v| v || EMPTY_VALUE }
        [key, entry]
      end
    prepend_css!(opt, css)
    sys_table(pairs, __method__, sort: sort, **opt)
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
