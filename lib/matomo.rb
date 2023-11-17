# lib/matomo.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Matomo analytics.
#
# @see https://analytics.lib.virginia.edu
#
module Matomo

  PROD_SITE = 52
  DEV_SITE  = 53

  SITE    = production_deployment? ? PROD_SITE : DEV_SITE

  HOST    = 'analytics.lib.virginia.edu'
  ROOT    = "https://#{HOST}"
  SCRIPT  = "#{ROOT}/matomo.js"
  TRACKER = "#{ROOT}/matomo.php"
  OPT_OUT = "#{ROOT}/index.php?module=CoreAdminHome&action=optOut&language=en"

  ENABLED =
    live_rails_application? &&
      ENV['ANALYTICS_ENABLED'].then do |setting|
        not_deployed? ? true?(setting) : !false?(setting)
      end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether Matomo analytics are in use.
  #
  # * If not running Rails, always *false*.
  # * If deployed, *true* unless `ENV[ANALYTICS_ENABLED]` is "false".
  # * On the desktop, *false* unless `ENV[ANALYTICS_ENABLED]` is "true".
  #
  def self.enabled? = ENABLED

  # Matomo site identifier ("idSite").
  #
  # The Matomo "site" or "project" is the data collection unit associated with
  # this service.
  #
  # @return [Integer]
  #
  def self.site = SITE

  # Matomo host tracker URL.
  #
  # @return [String]
  #
  def self.tracker_url = TRACKER

  # Matomo script URL.
  #
  # @return [String]
  #
  def self.script_url = SCRIPT

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Matomo JavaScript asset.
  #
  # This should be included at the end of `<head>`.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def self.script_element
    <<~HEREDOC.html_safe
      <script type="text/javascript">
        let _paq = window._paq = window._paq || [];
        _paq.push(['trackPageView']);
        _paq.push(['enableLinkTracking']);
        (function() {
          _paq.push(['setTrackerUrl', '#{tracker_url}']);
          _paq.push(['setSiteId', '#{site}']);
          const g = document.createElement('script');
          const s = document.getElementsByTagName('script')[0];
          g.async = true;
          g.src   = '#{script_url}';
          s.parentNode.insertBefore(g, s);
        })();
      </script>
    HEREDOC
  end

  # Element inserted to cause a page to be counted if JavaScript is disabled.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection SpellCheckingInspection
  #++
  def self.no_js(**opt)
    opt[:src]              = "#{tracker_url}?idsite=#{site}&rec=1"
    opt[:alt]            ||= ''
    opt[:style]          ||= 'border:0'
    opt[:referrerpolicy] ||= 'no-referrer-when-downgrade'
    opt = opt.map { |k, v| "#{k}='#{ERB::Util.h(v)}'" }.join(' ')
    "<img #{opt} />".html_safe
  end

end
