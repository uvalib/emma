# app/helpers/layout_helper/nav_bar.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the <header> nav bar.
#
module LayoutHelper::NavBar

  include LayoutHelper::Common

  include LinkHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Configuration for nav bar properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  NAV_BAR_CONFIG = I18n.t('emma.nav_bar', default: {}).deep_freeze

  # The controllers included on the nav bar.
  #
  # @type [Array<Symbol>]
  #
  # == Implementation Notes
  # Should contain some or all of superset ApplicationHelper#APP_CONTROLLERS.
  #
  NAV_BAR_CONTROLLERS = NAV_BAR_CONFIG[:controllers].map(&:to_sym).freeze

  # The important nav bar entries.
  #
  # @type [Array<Symbol>]
  #
  # == Implementation Notes
  # Should contain some or all of superset #PRIMARY_CONTROLLERS.
  #
  PRIMARY_CONTROLLERS = NAV_BAR_CONFIG[:primary].map(&:to_sym).freeze

  # Configuration for dashboard page properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  DASHBOARD_CONFIG = I18n.t('emma.home.dashboard', default: {}).deep_freeze

  # Default dashboard link label.
  #
  # @type [String]
  #
  DASHBOARD_LABEL = DASHBOARD_CONFIG[:label]

  # Default dashboard link tooltip.
  #
  # @type [String]
  #
  DASHBOARD_TOOLTIP = DASHBOARD_CONFIG[:tooltip]

  # Controller link labels.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_LABEL =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, I18n.t("emma.#{c}.label", default: c.to_s.camelize)]
    }.to_h.deep_freeze

  # Controller link tooltips.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_TOOLTIP =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, I18n.t("emma.#{c}.tooltip", default: '')]
    }.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the nav bar.
  #
  def show_nav_bar?(*)
    true
  end

  # Generate an element containing links for the main page of each controller.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def nav_bar_links
    curr_params = url_parameters.except(:limit)
    curr_path   = request.path
    base_path   = curr_path.sub(%r{^(/[^/]*)/.*$}, '\1')
    curr_path  += '?' + url_query(curr_params) if curr_params.present?
    html_div(class: 'links') do
      first = true
      NAV_BAR_CONTROLLERS.map do |controller|
        if controller == :home
          # Special entry for the dashboard/welcome screen.
          path   = dashboard_path
          label  = DASHBOARD_LABEL
          tip    = DASHBOARD_TOOLTIP
          hidden = !current_user
        else
          # Entry for the main page of the given controller.
          path   = get_path_for(controller)
          label  = CONTROLLER_LABEL[controller]
          tip    = CONTROLLER_TOOLTIP[controller]
          hidden = false
        end
        primary  = PRIMARY_CONTROLLERS.include?(controller)
        current  = (path == curr_path)
        base     = (path == base_path)
        active   = current || base
        disabled = current

        classes = []
        classes << 'secondary' unless primary
        classes << 'active'    if active
        classes << 'disabled'  if disabled
        classes << 'hidden'    if hidden

        # The separator preceding the link.
        sep_css = %w(separator)
        sep_css << 'hidden'    if first
        separator = html_span('|', class: css_classes(*classes, *sep_css))

        # The link (inactive if already on the associated page).
        tip &&= "#{tip}\n"       if disabled
        tip  += '(Current_page)' if disabled # TODO: I18n
        opt   = { class: css_classes(*classes), title: tip }
        link  = disabled ? html_span(label, opt) : link_to(label, path, opt)
        first = false unless hidden

        separator << link
      end
    end
  end

end

__loading_end(__FILE__)
