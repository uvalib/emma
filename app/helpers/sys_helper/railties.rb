# app/helpers/sys_helper/railties.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Railties

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table of loaded Rails::Railtie entries.
  #
  # @param [Boolean] sort
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #sys_table.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def application_railties(sort: false, css: '.railties-table', **opt)
    anon  = 0
    pairs =
      Rails::Railtie.subclasses.map do |obj|
        key   = obj.name.to_s.presence || "anonymous #{anon += 1}"
        obj   = obj.instance_variable_get(:@instance)
        id    = obj&.object_id
        entry = [id].map! { |v| v || EMPTY_VALUE }
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
