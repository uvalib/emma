# app/helpers/layout_helper/nav_bar.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::NavBar
#
module LayoutHelper::NavBar

  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # The controllers included on the nav bar.
  #
  # @type [Array<Symbol>]
  #
  # == Implementation Note
  # Should contain some or all of superset ApplicationHelper#APP_CONTROLLERS.
  #
  NAV_BAR_CONTROLLERS = I18n.t('emma.nav_bar.controllers').map(&:to_sym).freeze

  # The important nav bar entries.
  #
  # @type [Array<Symbol>]
  #
  # == Implementation Note
  # Should contain some or all of superset #PRIMARY_CONTROLLERS.
  #
  PRIMARY_CONTROLLERS = I18n.t('emma.nav_bar.primary').map(&:to_sym).freeze

  # Default dashboard link label.
  #
  # @type [String]
  #
  DASHBOARD_LABEL = I18n.t('emma.home.dashboard.label').freeze

  # Default dashboard link tooltip.
  #
  # @type [String]
  #
  DASHBOARD_TOOLTIP = I18n.t('emma.home.dashboard.tooltip', default: '').freeze

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
    # @type [Hash] curr_params
    curr_params = url_parameters.except(:limit)
    curr_path   = request.path
    base_path   = curr_path.sub(%r{^(/[^/]*)/.*$}, '\1')
    curr_path  += '?' + url_query(curr_params) if curr_params.present?
    html_div(class: 'links') do
      first = true
      NAV_BAR_CONTROLLERS.map do |c|
        if c == :home
          # Special entry for the dashboard/welcome screen.
          path    = dashboard_path
          label   = DASHBOARD_LABEL
          tooltip = DASHBOARD_TOOLTIP
          hidden  = !current_user
        else
          # Entry for the main page of the given controller.
          path    = send("#{c}_index_path")
          label   = CONTROLLER_LABEL[c]
          tooltip = CONTROLLER_TOOLTIP[c]
          hidden  = false
        end
        primary   = PRIMARY_CONTROLLERS.include?(c)
        current   = (path == curr_path)
        base      = (path == base_path)
        active    = current || base
        disabled  = current

        classes = []
        classes << 'secondary' unless primary
        classes << 'active'    if active
        classes << 'disabled'  if disabled
        classes << 'hidden'    if hidden

        # The separator preceding the link.
        separator_opt = { class: css_classes('separator', *classes) }
        append_css_classes!(separator_opt, 'hidden') if first
        separator = html_span('|', separator_opt)

        # The link (inactive if already on the associated page).
        opt   = { class: css_classes(*classes), title: tooltip }
        link  = disabled ? html_span(label, opt) : link_to(label, path, opt)
        first = false unless hidden

        separator << link
      end
    end
  end

end

__loading_end(__FILE__)
