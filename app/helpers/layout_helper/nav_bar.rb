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
  NAV_BAR_CONTROLLERS = I18n.t('emma.nav_bar.controllers').map(&:to_sym).freeze

  # The important nav bar entries
  #
  # @type [Array<Symbol>]
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
      [c, I18n.t("emma.#{c}.label", default: c.to_s.capitalize)]
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

    current_params = url_parameters.except(:limit)
    current_path   = request.path
    base_path      = current_path.sub(%r{^(/[^/]*)/.*$}, '\1')
    current_path  += '?' + current_params.to_param if current_params.present?

    links = []

    # Special entry for the dashboard/welcome screen.
    label = DASHBOARD_LABEL
    path  = dashboard_path
    opt   = { title: DASHBOARD_TOOLTIP }
    links <<
      if path == current_path
        content_tag(:span, label, opt.merge!(class: 'active disabled'))
      elsif !current_user
        content_tag(:span, label, opt.merge!(class: 'disabled'))
      elsif path == base_path
        link_to(label, path, opt.merge!(class: 'active'))
      else
        link_to(label, path, opt)
      end

    # Entries for the main page of each controller.
    links +=
      NAV_BAR_CONTROLLERS.map do |c|
        primary = PRIMARY_CONTROLLERS.include?(c)
        path    = send("#{c}_index_path")
        current = (path == current_path)
        base    = (path == base_path)

        # The separator preceding the link.
        separator_opt = { class: 'separator' }
        append_css_classes!(separator_opt, 'secondary') unless primary
        append_css_classes!(separator_opt, 'active')    if current || base
        separator = content_tag(:span, '|', separator_opt)

        # The link (inactive if already on the associated page).
        label = CONTROLLER_LABEL[c]
        opt   = { title: CONTROLLER_TOOLTIP[c] }
        opt[:class] = 'secondary' unless primary
        link  =
          if current
            append_css_classes!(opt, 'active', 'disabled')
            content_tag(:span, label, opt)
          elsif base
            append_css_classes!(opt, 'active')
            link_to(label, path, opt)
          else
            link_to(label, path, opt)
          end

        separator << link
      end

    # Element containing links.
    content_tag(:div, safe_join(links), class: 'links')
  end

end

__loading_end(__FILE__)
