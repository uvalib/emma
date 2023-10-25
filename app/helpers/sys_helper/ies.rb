# app/helpers/sys_helper/ies.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Ies

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Column headers for #application_ies.
  #
  # @type [Hash{Symbol=>String}]
  #
  APPLICATION_IES_HEADERS =
    I18n.t('emma.sys.application_ies.headers').deep_freeze

  # Render a table of current ActiveSupport::IsolatedExecutionState entries.
  #
  # @param [Boolean] sort
  # @param [String]  css              Characteristic CSS class/selector.
  # @param [Hash]    opt              Passed to #sys_table.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def application_ies(sort: true, css: '.ies-table', **opt)
    pairs =
      ActiveSupport::IsolatedExecutionState.send(:state).map do |key, val|
        key = key.to_s
        id  = val.object_id
        val = dd_value(val)
        entry = [id, val].map! { |v| v || EMPTY_VALUE }
        [key, entry]
      end
    prepend_css!(opt, css)
    sys_table(pairs, APPLICATION_IES_HEADERS, sort: sort, **opt)
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
