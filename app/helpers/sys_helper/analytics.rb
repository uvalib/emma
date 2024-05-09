# app/helpers/sys_helper/analytics.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper for Matomo Analytics information.
#
module SysHelper::Analytics

  include SysHelper::Common
  include LinkHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate an active HTML link to the Matomo analytics site.
  #
  # @param [String, nil] label        Display the URL if *nil*.
  # @param [Hash, nil]   matomo       Passed to Matomo#analytics_url.
  # @param [Hash]        opt          Passed to #external_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def analytics_link(label = 'Matomo analytics', matomo: nil, **opt)
    url     = Matomo.analytics_url(**(matomo || {}))
    label ||= ERB::Util.h(url)
    external_link(url, label, **opt)
  end

  # A descriptive phrase for the range of days covered by displayed analytics
  # information.
  #
  # @return [String]
  #
  def analytics_day_range
    Matomo::DEFAULT_RANGE.inspect
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Analytics summary information.
  #
  # @param [Hash] matomo              To Matomo#info.
  # @param [Hash] opt                 To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def analytics_info_section(matomo: nil, **opt)
    matomo = matomo&.dup || {}
    values = Matomo.info(**matomo)
    dt_dd_section(values, **opt)
  end

  # Analytics report graphs.
  #
  # @param [Hash]   matomo            To Matomo#reports.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               To #dt_dd_section.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def analytics_reports_section(matomo: nil, css: '.analytics-reports', **opt)
    matomo = { target: params[:format] }.merge!(matomo || {})
    values = Matomo.reports(**matomo)
    prepend_css!(opt, css)
    dt_dd_section(values, **opt)
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
