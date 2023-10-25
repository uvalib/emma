# app/helpers/sys_helper/loggers.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper supporting EMMA settings available to all workers/threads.
#
module SysHelper::Loggers

  include SysHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Column headers for #applicaton_loggers.
  #
  # @type [Hash{Symbol=>String}]
  #
  APPLICATION_LOGGERS_HEADERS =
    I18n.t('emma.sys.application_loggers.headers').deep_freeze

  # Render a table of loggers currently active for the application.
  #
  # Loggers which are only associated with ActiveSupport::LogSubscriber have
  # their names in parentheses.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #sys_table.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def application_loggers(css: '.logger-table', **opt)
    # Find loggers; skip Broadcast loggers that will have been already listed.
    loggers = ObjectSpace.each_object(::Logger).map(&:itself)
    ls_logs = ObjectSpace.each_object(ActiveSupport::LogSubscriber)
    ls_logs = ls_logs.map { |log| log.try(:logger) }.compact - loggers

    # Create a hash of loggers whose keys are a unique string based on the
    # logger's progname.
    pairs  = {}
    keygen =
      ->(log, fmt) do
        lbl = log.progname.to_s.presence || 'unnamed'
        key = fmt % lbl
        if pairs.key?(key)
          lbl = lbl.split(' ')
          num = positive(lbl.last)&.tap { lbl.pop } || 1
          key = fmt % [*lbl, num.succ].join(' ')
        end
        key
      end
    loggers.each { |log| key = keygen.(log, '%s');   pairs[key] = log }
    ls_logs.each { |log| key = keygen.(log, '(%s)'); pairs[key] = log }
    pairs.transform_values! do |log|
      [log.class.name, Log.level_name(log.level), dd_value(log)]
    end

    # Render the table of values.
    prepend_css!(opt, css)
    sys_table(pairs, APPLICATION_LOGGERS_HEADERS, sort: false, **opt)
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
